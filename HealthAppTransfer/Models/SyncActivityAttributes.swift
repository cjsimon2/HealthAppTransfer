#if canImport(ActivityKit)
import ActivityKit
import Foundation

// MARK: - Sync Activity Attributes

/// ActivityKit attributes for health data sync Live Activity.
/// Displays real-time sync progress on Dynamic Island and Lock Screen.
struct SyncActivityAttributes: ActivityAttributes {

    // MARK: - Static Properties

    /// Total number of health data types being synced.
    let totalTypes: Int

    /// When the sync session started.
    let startedAt: Date

    // MARK: - Content State

    struct ContentState: Codable, Hashable {
        /// Number of types synced so far.
        let typesSynced: Int

        /// Total samples fetched across all types.
        let totalSamples: Int

        /// Display name of the type currently being synced.
        let currentTypeName: String

        /// Sync progress from 0.0 to 1.0.
        let progress: Double

        /// Current sync status.
        let status: Status

        enum Status: String, Codable, Hashable {
            case syncing
            case completed
            case failed
        }
    }
}
#endif
