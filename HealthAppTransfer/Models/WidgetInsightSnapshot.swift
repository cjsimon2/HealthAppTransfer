import Foundation

// MARK: - Widget Insight Snapshot

/// Cached insight data for widget display.
/// Shared between main app and widget extension via App Group UserDefaults.
struct WidgetInsightSnapshot: Codable, Sendable {
    let id: String
    let iconName: String
    let metricName: String
    let message: String
    let categoryIconName: String
    let lastUpdated: Date
}
