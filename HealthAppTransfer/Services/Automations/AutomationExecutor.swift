import Foundation
import SwiftData

// MARK: - Automation Executor

/// Runs automation configurations, updating their status on success/failure.
/// Manages `consecutiveFailures` counter and `lastTriggeredAt` timestamp.
actor AutomationExecutor {

    // MARK: - Dependencies

    private let healthKitService: HealthKitService
    private let keychain: KeychainStore

    init(healthKitService: HealthKitService, keychain: KeychainStore = KeychainStore()) {
        self.healthKitService = healthKitService
        self.keychain = keychain
    }

    // MARK: - Execute

    /// Execute an automation based on its type. Updates the configuration on success/failure.
    /// Must be called from the main actor so SwiftData model access is safe.
    @MainActor
    func execute(configuration: AutomationConfiguration, in modelContext: ModelContext) async {
        switch configuration.automationType {
        case "rest_api":
            await executeREST(configuration: configuration, in: modelContext)
        case "mqtt":
            await executeMQTT(configuration: configuration, in: modelContext)
        case "cloud_storage":
            await executeCloudStorage(configuration: configuration, in: modelContext)
        case "calendar":
            await executeCalendar(configuration: configuration, in: modelContext)
        case "home_assistant":
            await executeHomeAssistant(configuration: configuration, in: modelContext)
        default:
            Loggers.automation.warning("AutomationExecutor: unsupported type '\(configuration.automationType)'")
        }
    }

    /// Execute a single REST automation.
    @MainActor
    func executeREST(configuration: AutomationConfiguration, in modelContext: ModelContext) async {
        let params = RESTPushParameters(configuration: configuration)
        let restAutomation = RESTAutomation(healthKitService: healthKitService)

        do {
            try await restAutomation.execute(params: params)
            markSuccess(configuration: configuration)
        } catch {
            markFailure(configuration: configuration, error: error)
        }

        try? modelContext.save()
    }

    /// Execute a single MQTT automation.
    @MainActor
    func executeMQTT(configuration: AutomationConfiguration, in modelContext: ModelContext) async {
        let params = MQTTPushParameters(configuration: configuration)
        let mqttAutomation = MQTTAutomation(healthKitService: healthKitService)

        do {
            try await mqttAutomation.execute(params: params)
            markSuccess(configuration: configuration)
        } catch {
            markFailure(configuration: configuration, error: error)
        }

        try? modelContext.save()
    }

    /// Execute a single iCloud Drive export automation.
    @MainActor
    func executeCloudStorage(configuration: AutomationConfiguration, in modelContext: ModelContext) async {
        let params = CloudStorageParameters(configuration: configuration)
        let cloudAutomation = CloudStorageAutomation(healthKitService: healthKitService)

        do {
            try await cloudAutomation.execute(params: params)
            markSuccess(configuration: configuration)
        } catch {
            markFailure(configuration: configuration, error: error)
        }

        try? modelContext.save()
    }

    /// Execute a single Calendar automation.
    @MainActor
    func executeCalendar(configuration: AutomationConfiguration, in modelContext: ModelContext) async {
        let params = CalendarParameters(configuration: configuration)
        let calendarAutomation = CalendarAutomation(healthKitService: healthKitService)

        do {
            try await calendarAutomation.execute(params: params)
            markSuccess(configuration: configuration)
        } catch {
            markFailure(configuration: configuration, error: error)
        }

        try? modelContext.save()
    }

    /// Execute a single Home Assistant automation.
    @MainActor
    func executeHomeAssistant(configuration: AutomationConfiguration, in modelContext: ModelContext) async {
        let keychainKey = HomeAssistantAutomation.keychainKeyPrefix + configuration.persistentModelID.hashValue.description

        // Load token from Keychain
        guard let tokenData = try? await keychain.load(key: keychainKey),
              let accessToken = String(data: tokenData, encoding: .utf8),
              !accessToken.isEmpty else {
            markFailure(configuration: configuration, error: HomeAssistantError.missingToken)
            try? modelContext.save()
            return
        }

        let params = HomeAssistantParameters(configuration: configuration, accessToken: accessToken)
        let haAutomation = HomeAssistantAutomation(healthKitService: healthKitService)

        do {
            try await haAutomation.execute(params: params)
            markSuccess(configuration: configuration)
        } catch {
            markFailure(configuration: configuration, error: error)
        }

        try? modelContext.save()
    }

    // MARK: - Status Helpers

    @MainActor
    private func markSuccess(configuration: AutomationConfiguration) {
        configuration.consecutiveFailures = 0
        configuration.lastTriggeredAt = Date()
        configuration.updatedAt = Date()
        Loggers.automation.info("Automation '\(configuration.name)' succeeded")
    }

    @MainActor
    private func markFailure(configuration: AutomationConfiguration, error: Error) {
        configuration.consecutiveFailures += 1
        configuration.updatedAt = Date()
        Loggers.automation.error("Automation '\(configuration.name)' failed (\(configuration.consecutiveFailures) consecutive): \(error.localizedDescription)")
    }
}
