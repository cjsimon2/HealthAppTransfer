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

    // MARK: - CloudKit Sync

    /// Whether CloudKit sync is enabled (supplements LAN sync).
    var isCloudKitEnabled: Bool = false

    /// Timestamp of the last successful CloudKit sync.
    var lastCloudKitSyncDate: Date?

    /// Number of samples uploaded in the last CloudKit sync.
    var lastCloudKitSampleCount: Int = 0

    /// Persisted CKServerChangeToken data for delta sync.
    var cloudKitChangeTokenData: Data?

    /// JSON-encoded array of recent sync history entries (last 20).
    var syncHistoryData: Data?

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
