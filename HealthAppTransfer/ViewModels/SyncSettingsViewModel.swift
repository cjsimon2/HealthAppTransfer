import Foundation
import SwiftData
import SwiftUI

// MARK: - Sync Frequency

enum SyncFrequency: Int, CaseIterable, Identifiable {
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600
    case fourHours = 14400
    case daily = 86400
    case manualOnly = 0

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fifteenMinutes: return "Every 15 min"
        case .thirtyMinutes: return "Every 30 min"
        case .oneHour: return "Every hour"
        case .fourHours: return "Every 4 hours"
        case .daily: return "Daily"
        case .manualOnly: return "Manual only"
        }
    }
}

// MARK: - Sync History Entry

struct SyncHistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let source: String
    let sampleCount: Int
    let success: Bool
    let errorMessage: String?

    init(
        date: Date = Date(),
        source: String,
        sampleCount: Int,
        success: Bool,
        errorMessage: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.source = source
        self.sampleCount = sampleCount
        self.success = success
        self.errorMessage = errorMessage
    }

    var sourceDisplayName: String {
        switch source {
        case "manual": return "Manual"
        case "background": return "Background"
        case "cloudkit": return "CloudKit"
        case "lan": return "LAN"
        default: return source.capitalized
        }
    }

    var sourceIcon: String {
        switch source {
        case "manual": return "hand.tap"
        case "background": return "clock.arrow.circlepath"
        case "cloudkit": return "icloud"
        case "lan": return "wifi"
        default: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Sync Settings ViewModel

@MainActor
class SyncSettingsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isCloudKitEnabled = false
    @Published var isLANSyncEnabled = true
    @Published var syncFrequency: SyncFrequency = .oneHour
    @Published var enabledTypes: Set<String> = []
    @Published var syncHistory: [SyncHistoryEntry] = []
    @Published var isSyncing = false
    @Published var syncProgress: String?
    @Published var error: String?
    @Published var lastSyncDate: Date?
    @Published var lastCloudKitSyncDate: Date?
    @Published var cloudKitRecordCount: Int = 0
    @Published var lastSyncSampleCount: Int = 0

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Load

    func loadConfiguration(from context: ModelContext) {
        let descriptor = FetchDescriptor<SyncConfiguration>()
        guard let config = try? context.fetch(descriptor).first else { return }

        isCloudKitEnabled = config.isCloudKitEnabled
        isLANSyncEnabled = config.isEnabled
        syncFrequency = SyncFrequency(rawValue: config.syncIntervalSeconds) ?? .oneHour
        enabledTypes = Set(config.enabledTypeRawValues)
        lastSyncDate = config.lastSyncDate
        lastSyncSampleCount = config.lastSyncSampleCount
        lastCloudKitSyncDate = config.lastCloudKitSyncDate
        cloudKitRecordCount = config.lastCloudKitSampleCount

        if let data = config.syncHistoryData,
           let entries = try? JSONDecoder().decode([SyncHistoryEntry].self, from: data) {
            syncHistory = entries
        }
    }

    // MARK: - Save

    func saveConfiguration(to context: ModelContext) {
        let descriptor = FetchDescriptor<SyncConfiguration>()
        let config: SyncConfiguration

        if let existing = try? context.fetch(descriptor).first {
            config = existing
        } else {
            config = SyncConfiguration()
            context.insert(config)
        }

        config.isCloudKitEnabled = isCloudKitEnabled
        config.isEnabled = isLANSyncEnabled
        config.syncIntervalSeconds = syncFrequency.rawValue
        config.enabledTypeRawValues = Array(enabledTypes)
        config.updatedAt = Date()

        if let data = try? JSONEncoder().encode(syncHistory) {
            config.syncHistoryData = data
        }

        try? context.save()
    }

    // MARK: - Type Selection

    func toggleType(_ rawValue: String, context: ModelContext) {
        if enabledTypes.contains(rawValue) {
            enabledTypes.remove(rawValue)
        } else {
            enabledTypes.insert(rawValue)
        }
        saveConfiguration(to: context)
    }

    func selectAllTypes(context: ModelContext) {
        enabledTypes = Set(HealthDataType.allCases.filter(\.isSampleBased).map(\.rawValue))
        saveConfiguration(to: context)
    }

    func deselectAllTypes(context: ModelContext) {
        enabledTypes.removeAll()
        saveConfiguration(to: context)
    }

    // MARK: - Manual Sync

    func syncNow(context: ModelContext) async {
        isSyncing = true
        syncProgress = "Starting sync..."
        error = nil

        guard HealthKitService.isAvailable else {
            error = "Health data is unavailable on this device"
            isSyncing = false
            syncProgress = nil

            let entry = SyncHistoryEntry(
                source: "manual",
                sampleCount: 0,
                success: false,
                errorMessage: "Health data is unavailable on this device"
            )
            addHistoryEntry(entry, context: context)
            return
        }

        do {
            let enabledDataTypes = enabledTypes.compactMap { HealthDataType(rawValue: $0) }
            let sampleBasedTypes = enabledDataTypes.filter(\.isSampleBased)

            guard !sampleBasedTypes.isEmpty else {
                error = "No health types selected for sync"
                isSyncing = false
                syncProgress = nil
                return
            }

            // Ensure HealthKit authorization (no-op if already granted)
            syncProgress = "Requesting HealthKit access..."
            try await healthKitService.requestAuthorization()

            let descriptor = FetchDescriptor<SyncConfiguration>()
            let config = try? context.fetch(descriptor).first
            let sinceDate = config?.incrementalOnly == true ? config?.lastSyncDate : config?.syncStartDate
            var totalSamples = 0

            for (index, type) in sampleBasedTypes.enumerated() {
                syncProgress = "Syncing \(type.displayName) (\(index + 1)/\(sampleBasedTypes.count))..."
                let samples = try await healthKitService.fetchSampleDTOs(for: type, from: sinceDate)
                totalSamples += samples.count
            }

            // Update config
            if let config {
                config.lastSyncDate = Date()
                config.lastSyncSampleCount = totalSamples
                config.updatedAt = Date()
                try context.save()
            }

            // Record history
            let entry = SyncHistoryEntry(
                source: "manual",
                sampleCount: totalSamples,
                success: true
            )
            addHistoryEntry(entry, context: context)

            // Reload
            loadConfiguration(from: context)

            Loggers.sync.info("Manual sync completed: \(totalSamples) samples")
        } catch {
            self.error = "Sync failed: \(error.localizedDescription)"

            let entry = SyncHistoryEntry(
                source: "manual",
                sampleCount: 0,
                success: false,
                errorMessage: error.localizedDescription
            )
            addHistoryEntry(entry, context: context)

            Loggers.sync.error("Manual sync failed: \(error.localizedDescription)")
        }

        isSyncing = false
        syncProgress = nil
    }

    // MARK: - Helpers

    private func addHistoryEntry(_ entry: SyncHistoryEntry, context: ModelContext) {
        syncHistory.insert(entry, at: 0)
        if syncHistory.count > 20 {
            syncHistory = Array(syncHistory.prefix(20))
        }
        saveConfiguration(to: context)
    }
}
