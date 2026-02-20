import Foundation

// MARK: - Audit Service

/// Actor that logs security and data-access events for accountability.
actor AuditService {

    // MARK: - Types

    enum AuditEvent: Sendable {
        case requestReceived(method: String, path: String)
        case pairingSucceeded
        case pairingFailed(reason: String)
        case dataAccessed(type: String, count: Int)
        case serverStarted(port: UInt16)
        case serverStopped
        case authorizationGranted
        case authorizationDenied
        case tokenRevoked
        case custom(category: String, message: String)
    }

    struct AuditEntry: Sendable {
        let timestamp: Date
        let event: AuditEvent
        let description: String
    }

    // MARK: - State

    private var entries: [AuditEntry] = []
    private let maxEntries: Int = 1000

    // MARK: - Logging

    /// Log an audit event.
    func log(event: AuditEvent) {
        let description = describeEvent(event)
        let entry = AuditEntry(timestamp: Date(), event: event, description: description)

        entries.append(entry)

        // Trim old entries if needed
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }

        Loggers.audit.info("\(description)")
    }

    // MARK: - Query

    /// Get all audit entries.
    var allEntries: [AuditEntry] {
        entries
    }

    /// Get the most recent N entries.
    func recentEntries(count: Int = 50) -> [AuditEntry] {
        Array(entries.suffix(count))
    }

    /// Clear all audit entries.
    func clear() {
        entries.removeAll()
    }

    // MARK: - Descriptions

    private func describeEvent(_ event: AuditEvent) -> String {
        switch event {
        case .requestReceived(let method, let path):
            return "HTTP \(method) \(path)"
        case .pairingSucceeded:
            return "Device pairing succeeded"
        case .pairingFailed(let reason):
            return "Device pairing failed: \(reason)"
        case .dataAccessed(let type, let count):
            return "Data accessed: \(type) (\(count) samples)"
        case .serverStarted(let port):
            return "Server started on port \(port)"
        case .serverStopped:
            return "Server stopped"
        case .authorizationGranted:
            return "HealthKit authorization granted"
        case .authorizationDenied:
            return "HealthKit authorization denied"
        case .tokenRevoked:
            return "Bearer token revoked"
        case .custom(let category, let message):
            return "[\(category)] \(message)"
        }
    }
}
