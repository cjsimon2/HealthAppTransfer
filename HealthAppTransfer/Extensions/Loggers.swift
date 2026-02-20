import OSLog

// MARK: - App Loggers

enum Loggers {
    static let healthKit = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "HealthKit")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Network")
    static let security = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Security")
    static let pairing = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Pairing")
    static let audit = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Audit")
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HealthAppTransfer", category: "Persistence")
}
