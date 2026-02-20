#if canImport(UIKit)
import BackgroundTasks
#endif
import Foundation
import HealthKit
import OSLog
import SwiftData

// MARK: - Background Sync Service

/// Manages background health data sync via BGTaskScheduler and HKObserverQuery.
/// Fetches new HealthKit samples since last sync and updates SyncConfiguration state.
actor BackgroundSyncService {

    // MARK: - Constants

    static let refreshTaskIdentifier = "com.caseysimon.HealthAppTransfer.refresh"
    static let exportTaskIdentifier = "com.caseysimon.HealthAppTransfer.export"

    // MARK: - Properties

    private let healthKitService: HealthKitService
    private let store: HKHealthStore
    private let modelContainer: ModelContainer
    private var observerQueries: [HKObserverQuery] = []

    // MARK: - Init

    init(healthKitService: HealthKitService, modelContainer: ModelContainer) {
        self.healthKitService = healthKitService
        self.store = HKHealthStore()
        self.modelContainer = modelContainer
    }

    // MARK: - BGTask Registration

    #if canImport(UIKit)
    /// Register background task handlers with the system.
    /// Must be called before the app finishes launching.
    nonisolated static func registerBackgroundTasks(service: BackgroundSyncService) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            Task { await service.handleAppRefresh(refreshTask) }
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: exportTaskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else { return }
            Task { await service.handleProcessingTask(processingTask) }
        }

        Loggers.sync.info("Background tasks registered")
    }

    /// Schedule the next app refresh task.
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
            Loggers.sync.info("Scheduled app refresh task")
        } catch {
            Loggers.sync.error("Failed to schedule app refresh: \(error.localizedDescription)")
        }
    }

    /// Schedule a processing task for heavy data exports.
    func scheduleProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: Self.exportTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            Loggers.sync.info("Scheduled processing task")
        } catch {
            Loggers.sync.error("Failed to schedule processing task: \(error.localizedDescription)")
        }
    }

    // MARK: - BGTask Handlers

    private func handleAppRefresh(_ task: BGAppRefreshTask) async {
        scheduleAppRefresh()

        let syncTask = Task { await performSync() }
        task.expirationHandler = { syncTask.cancel() }

        let success = await syncTask.value
        task.setTaskCompleted(success: success)
    }

    private func handleProcessingTask(_ task: BGProcessingTask) async {
        let syncTask = Task { await performSync() }
        task.expirationHandler = { syncTask.cancel() }

        let success = await syncTask.value
        task.setTaskCompleted(success: success)

        scheduleAppRefresh()
    }
    #endif

    // MARK: - Observer Queries

    /// Set up HKObserverQuery and background delivery for types in SyncConfiguration.
    func setupObserverQueries() async {
        stopObserverQueries()

        let enabledTypes = loadEnabledTypes()
        guard !enabledTypes.isEmpty else {
            Loggers.sync.info("No enabled types for observer queries")
            return
        }

        for type in enabledTypes where type.isSampleBased {
            let sampleType = type.sampleType

            #if os(iOS)
            do {
                try await store.enableBackgroundDelivery(for: sampleType, frequency: .hourly)
            } catch {
                Loggers.sync.error("Failed to enable background delivery for \(type.rawValue): \(error.localizedDescription)")
                continue
            }
            #endif

            let typeName = type.rawValue
            let query = HKObserverQuery(
                sampleType: sampleType,
                predicate: nil
            ) { [weak self] _, completionHandler, error in
                if let error {
                    Loggers.sync.error("Observer query error for \(typeName): \(error.localizedDescription)")
                    completionHandler()
                    return
                }

                guard let self else {
                    completionHandler()
                    return
                }

                Task {
                    await self.performSync()
                    completionHandler()
                }
            }

            store.execute(query)
            observerQueries.append(query)
        }

        Loggers.sync.info("Set up \(self.observerQueries.count) observer queries")
    }

    /// Stop all active observer queries.
    func stopObserverQueries() {
        for query in observerQueries {
            store.stop(query)
        }
        observerQueries.removeAll()
    }

    // MARK: - Sync

    /// Perform incremental sync: fetch new samples since last sync, update config.
    /// Returns true on success, false on failure.
    @discardableResult
    func performSync() async -> Bool {
        Loggers.sync.info("Starting background sync")

        do {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<SyncConfiguration>()

            guard let config = try context.fetch(descriptor).first else {
                Loggers.sync.warning("No SyncConfiguration found, skipping sync")
                return false
            }

            guard config.isEnabled else {
                Loggers.sync.info("Sync disabled, skipping")
                return true
            }

            let enabledTypes = config.enabledTypeRawValues.compactMap { HealthDataType(rawValue: $0) }
            guard !enabledTypes.isEmpty else {
                Loggers.sync.info("No enabled types, skipping sync")
                return true
            }

            let sinceDate = config.incrementalOnly ? config.lastSyncDate : config.syncStartDate
            var totalSamples = 0

            for type in enabledTypes where type.isSampleBased {
                let samples = try await healthKitService.fetchSampleDTOs(
                    for: type,
                    from: sinceDate
                )
                totalSamples += samples.count

                if !samples.isEmpty {
                    Loggers.sync.debug("Fetched \(samples.count) samples for \(type.rawValue)")
                }
            }

            config.lastSyncDate = Date()
            config.lastSyncSampleCount = totalSamples
            config.updatedAt = Date()
            try context.save()

            Loggers.sync.info("Background sync completed: \(totalSamples) samples")
            return true

        } catch {
            Loggers.sync.error("Background sync failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Helpers

    /// Read enabled types from SyncConfiguration.
    private func loadEnabledTypes() -> [HealthDataType] {
        do {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<SyncConfiguration>()
            guard let config = try context.fetch(descriptor).first else { return [] }
            return config.enabledTypeRawValues.compactMap { HealthDataType(rawValue: $0) }
        } catch {
            Loggers.sync.error("Failed to load enabled types: \(error.localizedDescription)")
            return []
        }
    }
}
