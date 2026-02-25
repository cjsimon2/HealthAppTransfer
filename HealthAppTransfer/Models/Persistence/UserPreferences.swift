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

    /// Custom daily goals keyed by HealthDataType.rawValue.
    var customGoals: [String: Double] = [:]

    /// Custom streak thresholds keyed by HealthDataType.rawValue.
    var customStreakThresholds: [String: Double] = [:]

    /// Whether push notifications are enabled.
    var notificationsEnabled: Bool = true

    /// Whether streak-at-risk alerts are enabled.
    var streakAlertsEnabled: Bool = true

    /// Whether goal-nearly-met alerts are enabled.
    var goalAlertsEnabled: Bool = true

    /// When preferences were last modified.
    var updatedAt: Date = Date()

    // MARK: - Init

    init() {
        self.updatedAt = Date()
    }
}
