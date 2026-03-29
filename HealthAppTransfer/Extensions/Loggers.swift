import OSLog

// MARK: - App Loggers

/// Centralised `Logger` instances for each subsystem used by the app.
///
/// Using named loggers (instead of raw `print` statements) lets you filter log
/// output by category in Console.app and in Xcode's debug console.
enum Loggers {
    static let healthKit = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "HealthKit")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Network")
    static let security = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Security")
    static let pairing = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Pairing")
    static let audit = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Audit")
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Persistence")
    static let bonjour = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Bonjour")
    static let sync = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Sync")
    static let cloudKit = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "CloudKit")
    static let automation = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Automation")
    static let export = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Export")
}
