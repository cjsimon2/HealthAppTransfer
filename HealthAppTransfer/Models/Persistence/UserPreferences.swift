import Foundation
import SwiftData

// MARK: - User Preferences

/// Persisted user preferences for the app. Singleton — only one instance should exist.
@Model
final class UserPreferences {

    // MARK: - Properties

    /// Whether onboarding has been completed.
    var hasCompletedOnboarding: Bool = false

    /// Whether HealthKit authorization has been requested.
    var hasRequestedHealthKitAuth: Bool = false

    /// Preferred export format: "json_v1", "json_v2", "csv", "gpx".
    var defaultExportFormat: String = "json_v2"

    /// Whether to require biometric auth (FaceID/TouchID) on launch.
    var requireBiometricAuth: Bool = false

    /// Whether to show sample counts on the dashboard.
    var showSampleCounts: Bool = true

    /// Preferred date range for dashboard charts: "week", "month", "year", "all".
    var dashboardDateRange: String = "week"

    /// Raw values of HealthDataType cases shown on the dashboard. Empty = default set.
    var dashboardMetricTypes: [String] = []

    /// Favorite correlation pairs stored as "typeA.rawValue|typeB.rawValue" strings.
    var favoriteCorrelationPairs: [String] = []

    /// When preferences were last modified.
    var updatedAt: Date = Date()

    // MARK: - Init

    init() {
        self.updatedAt = Date()
    }
}
