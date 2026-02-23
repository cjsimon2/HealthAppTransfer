#if os(iOS) && canImport(ActivityKit)
import ActivityKit
#endif
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
    private let cloudKitSync: CloudKitSyncService
    private var automationScheduler: AutomationScheduler?
    private var observerQueries: [HKObserverQuery] = []
    #if os(iOS) && canImport(ActivityKit)
    private var currentActivity: Activity<SyncActivityAttributes>?
    #endif

    // MARK: - Init

    init(healthKitService: HealthKitService, modelContainer: ModelContainer) {
        self.healthKitService = healthKitService
        self.store = HKHealthStore()
        self.modelContainer = modelContainer
        self.cloudKitSync = CloudKitSyncService(
            healthKitService: healthKitService,
            modelContainer: modelContainer
        )
    }

    // MARK: - Automation Scheduler

    /// Set the automation scheduler so automations fire during background sync.
    func setAutomationScheduler(_ scheduler: AutomationScheduler) {
        self.automationScheduler = scheduler
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

            #if os(iOS) && !targetEnvironment(macCatalyst)
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

        // Ensure HealthKit authorization before fetching — without this,
        // queries silently return zero results and the sync window advances.
        do {
            try await healthKitService.requestAuthorization()
        } catch {
            Loggers.sync.error("HealthKit authorization failed: \(error.localizedDescription)")
        }

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

            let sampleBasedTypes = enabledTypes.filter { $0.isSampleBased }
            let sinceDate = config.incrementalOnly ? config.lastSyncDate : config.syncStartDate
            var totalSamples = 0
            var typesSynced = 0

            #if os(iOS) && canImport(ActivityKit)
            startLiveActivity(totalTypes: sampleBasedTypes.count)
            #endif

            for type in sampleBasedTypes {
                let samples = try await healthKitService.fetchSampleDTOs(
                    for: type,
                    from: sinceDate
                )
                totalSamples += samples.count
                typesSynced += 1

                if !samples.isEmpty {
                    Loggers.sync.debug("Fetched \(samples.count) samples for \(type.rawValue)")
                }

                #if os(iOS) && canImport(ActivityKit)
                await updateLiveActivity(
                    typesSynced: typesSynced,
                    totalSamples: totalSamples,
                    currentTypeName: type.displayName,
                    totalTypes: sampleBasedTypes.count
                )
                #endif
            }

            config.lastSyncDate = Date()
            config.lastSyncSampleCount = totalSamples
            config.updatedAt = Date()
            try context.save()

            Loggers.sync.info("Background sync completed: \(totalSamples) samples")

            #if os(iOS) && canImport(ActivityKit)
            await endLiveActivity(
                totalSamples: totalSamples,
                totalTypes: sampleBasedTypes.count,
                success: true
            )
            #endif

            // Trigger CloudKit sync after local sync (non-blocking on errors)
            await cloudKitSync.performSync()

            // Fire active automations after sync
            await automationScheduler?.executeAll()

            return true

        } catch {
            Loggers.sync.error("Background sync failed: \(error.localizedDescription)")

            #if os(iOS) && canImport(ActivityKit)
            await endLiveActivity(totalSamples: 0, totalTypes: 0, success: false)
            #endif

            return false
        }
    }

    // MARK: - Live Activity

    #if os(iOS) && canImport(ActivityKit)
    /// Start a Live Activity to show sync progress on Dynamic Island and Lock Screen.
    private func startLiveActivity(totalTypes: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Loggers.sync.debug("Live Activities not enabled, skipping")
            return
        }

        // End any stale activity from a previous sync
        if let existing = currentActivity {
            Task {
                await existing.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }

        let attributes = SyncActivityAttributes(
            totalTypes: totalTypes,
            startedAt: Date()
        )
        let initialState = SyncActivityAttributes.ContentState(
            typesSynced: 0,
            totalSamples: 0,
            currentTypeName: "Starting...",
            progress: 0,
            status: .syncing
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            Loggers.sync.info("Started sync live activity")
        } catch {
            Loggers.sync.error("Failed to start live activity: \(error.localizedDescription)")
        }
    }

    /// Update the Live Activity with current sync progress.
    private func updateLiveActivity(
        typesSynced: Int,
        totalSamples: Int,
        currentTypeName: String,
        totalTypes: Int
    ) async {
        guard let activity = currentActivity else { return }

        let state = SyncActivityAttributes.ContentState(
            typesSynced: typesSynced,
            totalSamples: totalSamples,
            currentTypeName: currentTypeName,
            progress: totalTypes > 0 ? Double(typesSynced) / Double(totalTypes) : 0,
            status: .syncing
        )
        await activity.update(.init(state: state, staleDate: nil))
    }

    /// End the Live Activity with final status.
    private func endLiveActivity(totalSamples: Int, totalTypes: Int, success: Bool) async {
        guard let activity = currentActivity else { return }

        let finalState = SyncActivityAttributes.ContentState(
            typesSynced: success ? totalTypes : 0,
            totalSamples: totalSamples,
            currentTypeName: success ? "Complete" : "Failed",
            progress: success ? 1.0 : 0,
            status: success ? .completed : .failed
        )

        // Keep completed activity visible for 30 seconds, dismiss failures immediately
        let dismissalPolicy: ActivityUIDismissalPolicy = success
            ? .after(.now + 30)
            : .after(.now + 10)

        await activity.end(
            .init(state: finalState, staleDate: nil),
            dismissalPolicy: dismissalPolicy
        )
        currentActivity = nil
        Loggers.sync.info("Ended sync live activity (success: \(success))")
    }
    #endif

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
