import Foundation
import SwiftData

// MARK: - Automation Configuration

/// Persisted configuration for an automation (REST API, MQTT, Home Assistant, etc.).
@Model
final class AutomationConfiguration {

    // MARK: - Properties

    /// Human-readable name for this automation.
    var name: String

    /// Type: "rest_api", "mqtt", "home_assistant", "cloud_storage", "calendar".
    var automationType: String

    /// Whether this automation is active.
    var isEnabled: Bool = true

    /// Target URL or host (e.g., REST endpoint, MQTT broker).
    var endpoint: String?

    /// Port for network-based automations.
    var port: Int?

    /// Topic for MQTT automations.
    var topic: String?

    /// Export format to use: "json_v1", "json_v2", "csv".
    var exportFormat: String = "json_v2"

    /// HealthKit types to include (stored as raw strings).
    var enabledTypeRawValues: [String] = []

    /// Trigger interval in seconds (0 = on-change only).
    var triggerIntervalSeconds: Int = 0

    /// Whether to send only changes since last push.
    var incrementalOnly: Bool = true

    /// Timestamp of the last successful push.
    var lastTriggeredAt: Date?

    /// Number of consecutive failures (resets on success).
    var consecutiveFailures: Int = 0

    /// When this automation was created.
    var createdAt: Date = Date()

    /// When this automation was last modified.
    var updatedAt: Date = Date()

    // MARK: - Init

    init(
        name: String,
        automationType: String,
        endpoint: String? = nil,
        exportFormat: String = "json_v2"
    ) {
        self.name = name
        self.automationType = automationType
        self.endpoint = endpoint
        self.exportFormat = exportFormat
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
