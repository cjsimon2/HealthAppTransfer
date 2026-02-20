import Foundation

// MARK: - Widget Metric Snapshot

/// Cached health metric data for widget display.
/// Shared between main app and widget extension via App Group UserDefaults.
struct WidgetMetricSnapshot: Codable, Sendable, Identifiable {
    var id: String { metricType }

    /// HealthDataType raw value identifier.
    let metricType: String

    /// Human-readable name (e.g., "Step Count").
    let displayName: String

    /// SF Symbol name for the metric's category.
    let iconName: String

    /// Most recent aggregated value.
    let currentValue: Double?

    /// Display unit string (e.g., "steps", "bpm").
    let unit: String

    /// Daily values for the last 7 days (sparkline data).
    let sparklineValues: [Double]

    /// When this snapshot was last refreshed.
    let lastUpdated: Date
}
