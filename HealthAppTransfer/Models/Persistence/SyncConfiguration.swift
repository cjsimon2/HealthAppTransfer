import Foundation
import SwiftData

// MARK: - Sync Configuration

/// Persisted configuration for background health data sync.
@Model
final class SyncConfiguration {

    // MARK: - Properties

    /// Whether background sync is enabled.
    var isEnabled: Bool = true

    /// Minimum interval (in seconds) between background syncs.
    var syncIntervalSeconds: Int = 3600

    /// HealthKit data types enabled for sync (stored as raw strings).
    var enabledTypeRawValues: [String] = []

    /// Date range start for sync (nil = all history).
    var syncStartDate: Date?

    /// Whether to sync only new data since last sync.
    var incrementalOnly: Bool = true

    /// Timestamp of the last successful sync.
    var lastSyncDate: Date?

    /// Number of samples transferred in the last sync.
    var lastSyncSampleCount: Int = 0

    /// Creation timestamp.
    var createdAt: Date = Date()

    /// Last modification timestamp.
    var updatedAt: Date = Date()

    // MARK: - Init

    init(
        isEnabled: Bool = true,
        syncIntervalSeconds: Int = 3600,
        enabledTypeRawValues: [String] = [],
        incrementalOnly: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.syncIntervalSeconds = syncIntervalSeconds
        self.enabledTypeRawValues = enabledTypeRawValues
        self.incrementalOnly = incrementalOnly
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
