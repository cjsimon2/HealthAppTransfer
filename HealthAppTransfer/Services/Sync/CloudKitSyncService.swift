import CloudKit
import Foundation
import OSLog
import SwiftData

// MARK: - CloudKit Sync Error

enum CloudKitSyncError: LocalizedError {
    case notAuthenticated
    case quotaExceeded
    case networkUnavailable
    case zoneCreationFailed(Error)
    case uploadFailed(Error)
    case downloadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "iCloud account not available"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .networkUnavailable:
            return "Network unavailable for CloudKit sync"
        case .zoneCreationFailed(let error):
            return "Failed to create CloudKit zone: \(error.localizedDescription)"
        case .uploadFailed(let error):
            return "CloudKit upload failed: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "CloudKit download failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - CloudKit Sync Service

/// Manages CloudKit private database sync for health data transfer between devices.
/// Uses a custom record zone with delta sync via CKServerChangeToken.
actor CloudKitSyncService {

    // MARK: - Constants

    private static let uploadBatchSize = 400

    // MARK: - Properties

    private let container: CKContainer
    private let database: CKDatabase
    private let modelContainer: ModelContainer
    private let healthKitService: HealthKitService
    private var zoneCreated = false

    // MARK: - Init

    init(healthKitService: HealthKitService, modelContainer: ModelContainer) {
        self.container = CKContainer.default()
        self.database = CKContainer.default().privateCloudDatabase
        self.modelContainer = modelContainer
        self.healthKitService = healthKitService
    }

    // MARK: - Zone Setup

    /// Ensures the custom record zone exists. Called before any upload/download.
    private func ensureZoneExists() async throws {
        guard !zoneCreated else { return }

        let zone = CKRecordZone(zoneID: CloudKitRecordMapper.zoneID)
        do {
            _ = try await database.save(zone)
            zoneCreated = true
            Loggers.cloudKit.info("Created CloudKit zone: \(CloudKitRecordMapper.zoneName)")
        } catch let error as CKError where error.code == .serverRecordChanged || error.code == .zoneNotFound {
            // Zone already exists or transient issue — retry save
            _ = try await database.save(zone)
            zoneCreated = true
        } catch {
            throw CloudKitSyncError.zoneCreationFailed(error)
        }
    }

    // MARK: - Account Check

    /// Verifies the user has an active iCloud account.
    private func checkAccountStatus() async throws {
        let status = try await container.accountStatus()
        guard status == .available else {
            throw CloudKitSyncError.notAuthenticated
        }
    }

    // MARK: - Upload

    /// Uploads new health samples to CloudKit private database.
    /// Fetches samples since the last CloudKit sync date and uploads in batches of 400.
    func uploadSamples() async throws -> Int {
        try await checkAccountStatus()
        try await ensureZoneExists()

        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SyncConfiguration>()

        guard let config = try context.fetch(descriptor).first,
              config.isCloudKitEnabled else {
            Loggers.cloudKit.info("CloudKit sync disabled, skipping upload")
            return 0
        }

        let enabledTypes = config.enabledTypeRawValues.compactMap { HealthDataType(rawValue: $0) }
        guard !enabledTypes.isEmpty else {
            Loggers.cloudKit.info("No enabled types for CloudKit upload")
            return 0
        }

        let sinceDate = config.lastCloudKitSyncDate
        var totalUploaded = 0

        for type in enabledTypes where type.isSampleBased {
            let samples = try await healthKitService.fetchSampleDTOs(for: type, from: sinceDate)
            guard !samples.isEmpty else { continue }

            let uploaded = try await uploadBatched(samples: samples)
            totalUploaded += uploaded

            Loggers.cloudKit.debug("Uploaded \(uploaded) \(type.rawValue) samples to CloudKit")
        }

        // Update sync state
        config.lastCloudKitSyncDate = Date()
        config.lastCloudKitSampleCount = totalUploaded
        config.updatedAt = Date()
        try context.save()

        Loggers.cloudKit.info("CloudKit upload completed: \(totalUploaded) samples")
        return totalUploaded
    }

    /// Uploads samples in batches using CKModifyRecordsOperation.
    private func uploadBatched(samples: [HealthSampleDTO]) async throws -> Int {
        var totalSaved = 0

        for batchStart in stride(from: 0, to: samples.count, by: Self.uploadBatchSize) {
            let batchEnd = min(batchStart + Self.uploadBatchSize, samples.count)
            let batch = samples[batchStart..<batchEnd]
            let records = batch.map { CloudKitRecordMapper.record(from: $0) }

            do {
                let (savedResults, _) = try await database.modifyRecords(
                    saving: records,
                    deleting: [],
                    savePolicy: .changedKeys,
                    atomicZone: false
                )
                totalSaved += savedResults.count
            } catch let error as CKError {
                throw classifyError(error)
            }
        }

        return totalSaved
    }

    // MARK: - Download (Delta Sync)

    /// Downloads new records from CloudKit since the last change token.
    /// Returns downloaded DTOs for local processing.
    /// Also persists downloaded samples as SyncedHealthSample in SwiftData.
    func downloadSamples() async throws -> [HealthSampleDTO] {
        try await checkAccountStatus()
        try await ensureZoneExists()

        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SyncConfiguration>()

        guard let config = try context.fetch(descriptor).first,
              config.isCloudKitEnabled else {
            Loggers.cloudKit.info("CloudKit sync disabled, skipping download")
            return []
        }

        // Restore persisted change token
        var changeToken: CKServerChangeToken?
        if let tokenData = config.cloudKitChangeTokenData {
            changeToken = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: CKServerChangeToken.self,
                from: tokenData
            )
        }

        let (samples, newToken) = try await fetchChanges(since: changeToken)

        // Persist downloaded samples to SwiftData (primary store on macOS)
        for dto in samples {
            let id = dto.id
            let sampleDescriptor = FetchDescriptor<SyncedHealthSample>(
                predicate: #Predicate { $0.sampleID == id }
            )
            if (try? context.fetchCount(sampleDescriptor)) ?? 0 == 0 {
                context.insert(SyncedHealthSample(from: dto, syncSource: "cloudkit"))
            }
        }

        // Persist the new change token
        if let newToken {
            config.cloudKitChangeTokenData = try? NSKeyedArchiver.archivedData(
                withRootObject: newToken,
                requiringSecureCoding: true
            )
        }
        config.updatedAt = Date()
        try context.save()

        Loggers.cloudKit.info("CloudKit download completed: \(samples.count) samples (delta sync)")
        return samples
    }

    /// Fetches changed records from the custom zone using CKFetchRecordZoneChangesOperation.
    private func fetchChanges(
        since token: CKServerChangeToken?
    ) async throws -> ([HealthSampleDTO], CKServerChangeToken?) {
        var allSamples: [HealthSampleDTO] = []
        var finalToken: CKServerChangeToken? = token
        var moreComing = true

        while moreComing {
            let (samples, newToken, hasMore) = try await fetchChangeBatch(since: finalToken)
            allSamples.append(contentsOf: samples)
            if let newToken { finalToken = newToken }
            moreComing = hasMore
        }

        return (allSamples, finalToken)
    }

    /// Fetches a single batch of changes from CloudKit.
    private func fetchChangeBatch(
        since token: CKServerChangeToken?
    ) async throws -> ([HealthSampleDTO], CKServerChangeToken?, Bool) {
        let zoneID = CloudKitRecordMapper.zoneID

        var options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        options.previousServerChangeToken = token

        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID],
            configurationsByRecordZoneID: [zoneID: options]
        )

        var changedRecords: [CKRecord] = []
        var newToken: CKServerChangeToken?
        var moreComing = false

        return try await withCheckedThrowingContinuation { continuation in
            operation.recordWasChangedBlock = { _, result in
                if case .success(let record) = result {
                    changedRecords.append(record)
                }
            }

            operation.recordZoneFetchResultBlock = { _, result in
                switch result {
                case .success(let (serverChangeToken, _, hasMoreComing)):
                    newToken = serverChangeToken
                    moreComing = hasMoreComing
                case .failure(let error):
                    Loggers.cloudKit.error("Zone fetch error: \(error.localizedDescription)")
                }
            }

            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    let samples = changedRecords.compactMap { CloudKitRecordMapper.dto(from: $0) }
                    continuation.resume(returning: (samples, newToken, moreComing))
                case .failure(let error):
                    continuation.resume(throwing: CloudKitSyncError.downloadFailed(error))
                }
            }

            database.add(operation)
        }
    }

    // MARK: - Full Sync

    /// Performs a complete sync cycle: upload then download.
    /// Returns (uploaded, downloaded) counts.
    @discardableResult
    func performSync() async -> (uploaded: Int, downloaded: Int) {
        do {
            let uploaded = try await uploadSamples()
            let downloaded = try await downloadSamples()
            return (uploaded, downloaded.count)
        } catch {
            Loggers.cloudKit.error("CloudKit sync failed: \(error.localizedDescription)")
            return (0, 0)
        }
    }

    // MARK: - Error Classification

    private func classifyError(_ error: CKError) -> CloudKitSyncError {
        switch error.code {
        case .notAuthenticated:
            return .notAuthenticated
        case .quotaExceeded:
            return .quotaExceeded
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .serverRecordChanged:
            // Conflict — changedKeys policy handles most cases
            return .uploadFailed(error)
        default:
            return .uploadFailed(error)
        }
    }
}
