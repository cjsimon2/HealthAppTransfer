import AppIntents

// MARK: - App Shortcuts Provider

/// Registers App Intents with the Shortcuts app for discovery.
struct HealthAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLatestValueIntent(),
            phrases: [
                "Get my latest \(\.$type) from \(.applicationName)",
                "What's my latest \(\.$type) in \(.applicationName)",
                "Show \(\.$type) from \(.applicationName)",
            ],
            shortTitle: "Get Health Value",
            systemImageName: "heart.text.square"
        )

        AppShortcut(
            intent: SyncNowIntent(),
            phrases: [
                "Sync health data with \(.applicationName)",
                "Sync \(.applicationName) now",
            ],
            shortTitle: "Sync Now",
            systemImageName: "arrow.triangle.2.circlepath"
        )

        AppShortcut(
            intent: ExportHealthDataIntent(),
            phrases: [
                "Export health data from \(.applicationName)",
                "Export \(\.$types) from \(.applicationName)",
            ],
            shortTitle: "Export Health Data",
            systemImageName: "square.and.arrow.up"
        )
    }
}
