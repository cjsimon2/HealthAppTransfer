import Foundation
import HealthKit
import SwiftData

// MARK: - Automation Scheduler

/// Orchestrates all active automations: loads configurations from SwiftData,
/// sets up HKObserverQuery triggers for on-change automations, runs interval-based
/// timers, and dispatches execution to AutomationExecutor.
actor AutomationScheduler {

    // MARK: - Dependencies

    private let healthKitService: HealthKitService
    private let modelContainer: ModelContainer
    private let executor: AutomationExecutor
    private let store: HKHealthStore

    // MARK: - State

    private var observerQueries: [String: [HKObserverQuery]] = [:]
    private var intervalTimers: [String: Task<Void, Never>] = [:]
    private var notificationTask: Task<Void, Never>?
    private var isRunning = false

    // MARK: - Init

    init(healthKitService: HealthKitService, modelContainer: ModelContainer, keychain: KeychainStore = KeychainStore()) {
        self.healthKitService = healthKitService
        self.modelContainer = modelContainer
        self.executor = AutomationExecutor(healthKitService: healthKitService, keychain: keychain)
        self.store = HKHealthStore()
    }

    // MARK: - Lifecycle

    /// Start the scheduler: load all active automations and set up triggers.
    func start() async {
        guard !isRunning else { return }
        isRunning = true
        Loggers.automation.info("AutomationScheduler starting")
        await reload()
        observeConfigChanges()
    }

    /// Stop all observer queries and interval timers.
    func stop() {
        isRunning = false
        notificationTask?.cancel()
        notificationTask = nil
        stopAllQueries()
        stopAllTimers()
        Loggers.automation.info("AutomationScheduler stopped")
    }

    /// Listen for .automationsDidChange notifications and reload.
    private func observeConfigChanges() {
        notificationTask?.cancel()
        notificationTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .automationsDidChange)
            for await _ in notifications {
                guard !Task.isCancelled else { break }
                await self?.reload()
            }
        }
    }

    /// Reload automations from SwiftData and reconfigure triggers.
    /// Call this when automations are added, removed, or toggled.
    func reload() async {
        stopAllQueries()
        stopAllTimers()

        let configs = loadActiveConfigurations()
        guard !configs.isEmpty else {
            Loggers.automation.info("No active automations to schedule")
            return
        }

        for config in configs {
            let configID = config.id
            let triggerInterval = config.triggerInterval
            let typeRawValues = config.typeRawValues

            if triggerInterval > 0 {
                setupIntervalTimer(configID: configID, intervalSeconds: triggerInterval)
            }

            // Always set up on-change observers for configured health types
            if !typeRawValues.isEmpty {
                setupObserverQueries(configID: configID, typeRawValues: typeRawValues)
            }
        }

        Loggers.automation.info("Scheduled \(configs.count) active automations (\(self.observerQueries.count) with observers, \(self.intervalTimers.count) with timers)")
    }

    /// Execute all active automations once (used by BackgroundSyncService).
    func executeAll() async {
        let configs = loadActiveConfigurations()
        guard !configs.isEmpty else { return }

        Loggers.automation.info("Executing all \(configs.count) active automations")

        for config in configs {
            await executeAutomation(configID: config.id)
        }
    }

    /// Execute a single automation by its persistent model ID string.
    func executeAutomation(configID: String) async {
        await MainActor.run {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<AutomationConfiguration>(
                predicate: #Predicate { $0.isEnabled }
            )

            guard let configurations = try? context.fetch(descriptor) else { return }

            // Match by hashValue string since PersistentIdentifier isn't directly queryable
            guard let config = configurations.first(where: {
                $0.persistentModelID.hashValue.description == configID
            }) else {
                Loggers.automation.warning("Automation config \(configID) not found or disabled")
                return
            }

            Task { @MainActor in
                await self.executor.execute(configuration: config, in: context)
            }
        }
    }

    // MARK: - Observer Queries (On-Change Trigger)

    private func setupObserverQueries(configID: String, typeRawValues: [String]) {
        let types = typeRawValues.compactMap { HealthDataType(rawValue: $0) }
            .filter { $0.isSampleBased }

        guard !types.isEmpty else { return }

        var queries: [HKObserverQuery] = []

        for type in types {
            let sampleType = type.sampleType
            let typeName = type.rawValue
            let capturedConfigID = configID

            let query = HKObserverQuery(
                sampleType: sampleType,
                predicate: nil
            ) { [weak self] _, completionHandler, error in
                if let error {
                    Loggers.automation.error("Observer query error for \(typeName): \(error.localizedDescription)")
                    completionHandler()
                    return
                }

                guard let self else {
                    completionHandler()
                    return
                }

                Task {
                    await self.executeAutomation(configID: capturedConfigID)
                    completionHandler()
                }
            }

            store.execute(query)
            queries.append(query)
        }

        observerQueries[configID] = queries
    }

    private func stopAllQueries() {
        for (_, queries) in observerQueries {
            for query in queries {
                store.stop(query)
            }
        }
        observerQueries.removeAll()
    }

    // MARK: - Interval Timers

    private func setupIntervalTimer(configID: String, intervalSeconds: Int) {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(intervalSeconds))
                guard !Task.isCancelled else { break }
                await self?.executeAutomation(configID: configID)
            }
        }
        intervalTimers[configID] = task
    }

    private func stopAllTimers() {
        for (_, task) in intervalTimers {
            task.cancel()
        }
        intervalTimers.removeAll()
    }

    // MARK: - SwiftData Helpers

    /// Sendable snapshot of an AutomationConfiguration for scheduling purposes.
    private struct ConfigSnapshot: Sendable {
        let id: String
        let triggerInterval: Int
        let typeRawValues: [String]
    }

    /// Load active automation configs as sendable snapshots.
    private func loadActiveConfigurations() -> [ConfigSnapshot] {
        do {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<AutomationConfiguration>(
                predicate: #Predicate { $0.isEnabled }
            )
            let configs = try context.fetch(descriptor)
            return configs.map { config in
                ConfigSnapshot(
                    id: config.persistentModelID.hashValue.description,
                    triggerInterval: config.triggerIntervalSeconds,
                    typeRawValues: config.enabledTypeRawValues
                )
            }
        } catch {
            Loggers.automation.error("Failed to load automation configs: \(error.localizedDescription)")
            return []
        }
    }
}
