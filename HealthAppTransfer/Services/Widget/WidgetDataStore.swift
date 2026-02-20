import Foundation

// MARK: - Widget Data Store

/// Reads and writes health metric snapshots to App Group UserDefaults.
/// Used by both the main app (writes) and widget extension (reads).
final class WidgetDataStore: @unchecked Sendable {

    // MARK: - Constants

    static let appGroupID = "group.com.caseysimon.HealthAppTransfer"
    private static let snapshotsKey = "widget_metric_snapshots"

    // MARK: - Singleton

    static let shared = WidgetDataStore()

    // MARK: - Properties

    private let defaults: UserDefaults?

    init(suiteName: String = WidgetDataStore.appGroupID) {
        defaults = UserDefaults(suiteName: suiteName)
    }

    // MARK: - Write

    func save(_ snapshots: [WidgetMetricSnapshot]) {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        defaults?.set(data, forKey: Self.snapshotsKey)
    }

    // MARK: - Read

    func loadAll() -> [WidgetMetricSnapshot] {
        guard let data = defaults?.data(forKey: Self.snapshotsKey),
              let snapshots = try? JSONDecoder().decode([WidgetMetricSnapshot].self, from: data) else {
            return []
        }
        return snapshots
    }

    func snapshot(for metricType: String) -> WidgetMetricSnapshot? {
        loadAll().first { $0.metricType == metricType }
    }
}
