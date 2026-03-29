/// App Intent that triggers an on-demand health data sync from Shortcuts or Siri.
///
/// Creates its own `BackgroundSyncService` instance rather than reusing the
/// app's shared service so the intent can run without the app being in the
/// foreground.
import AppIntents
import Foundation
import SwiftData

// MARK: - Sync Now Intent

/// Triggers an immediate background health data sync.
/// Available in Shortcuts app, Siri, and Action button.
struct SyncNowIntent: AppIntent {

    static var title: LocalizedStringResource = "Sync Health Data Now"
    static var description = IntentDescription(
        "Trigger an immediate sync of your health data.",
        categoryName: "Health Data"
    )
    static var openAppWhenRun = false

    // MARK: - Parameter Summary

    static var parameterSummary: some ParameterSummary {
        Summary("Sync health data now")
    }

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let healthKitService = HealthKitService()
        try await healthKitService.requestAuthorization()

        let modelContainer = try PersistenceConfiguration.makeModelContainer()
        let syncService = BackgroundSyncService(
            healthKitService: healthKitService,
            modelContainer: modelContainer
        )

        let success = await syncService.performSync()

        guard success else {
            throw IntentError.syncFailed
        }

        return .result(value: "Sync completed successfully.")
    }
}
