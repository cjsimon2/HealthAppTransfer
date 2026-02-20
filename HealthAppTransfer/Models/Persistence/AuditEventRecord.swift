import Foundation
import SwiftData

// MARK: - Audit Event Record

/// Persisted audit trail entry for security and data-access events.
@Model
final class AuditEventRecord {

    // MARK: - Properties

    /// Category of the event (e.g., "pairing", "dataAccess", "server", "auth").
    var category: String

    /// Human-readable description of what happened.
    var message: String

    /// Severity: "info", "warning", "error".
    var severity: String = "info"

    /// When the event occurred.
    var timestamp: Date = Date()

    /// Optional device ID associated with this event.
    var deviceID: String?

    /// Optional IP address associated with this event.
    var ipAddress: String?

    // MARK: - Init

    init(
        category: String,
        message: String,
        severity: String = "info",
        deviceID: String? = nil,
        ipAddress: String? = nil
    ) {
        self.category = category
        self.message = message
        self.severity = severity
        self.timestamp = Date()
        self.deviceID = deviceID
        self.ipAddress = ipAddress
    }
}
