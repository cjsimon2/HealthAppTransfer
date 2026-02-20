import Foundation
import SwiftData

// MARK: - Automation Executor

/// Runs automation configurations, updating their status on success/failure.
/// Manages `consecutiveFailures` counter and `lastTriggeredAt` timestamp.
actor AutomationExecutor {

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Execute

    /// Execute a single REST automation. Updates the configuration on success/failure.
    /// Must be called from the main actor so SwiftData model access is safe.
    @MainActor
    func executeREST(configuration: AutomationConfiguration, in modelContext: ModelContext) async {
        guard configuration.automationType == "rest_api" else {
            Loggers.automation.warning("AutomationExecutor: unsupported type '\(configuration.automationType)'")
            return
        }

        // Snapshot configuration values on main actor before crossing to RESTAutomation actor
        let params = RESTPushParameters(configuration: configuration)
        let restAutomation = RESTAutomation(healthKitService: healthKitService)

        do {
            try await restAutomation.execute(params: params)

            // Success: reset failures, update timestamp
            configuration.consecutiveFailures = 0
            configuration.lastTriggeredAt = Date()
            configuration.updatedAt = Date()

            Loggers.automation.info("Automation '\(configuration.name)' succeeded")
        } catch {
            // Failure: increment counter
            configuration.consecutiveFailures += 1
            configuration.updatedAt = Date()

            Loggers.automation.error("Automation '\(configuration.name)' failed (\(configuration.consecutiveFailures) consecutive): \(error.localizedDescription)")
        }

        try? modelContext.save()
    }
}
