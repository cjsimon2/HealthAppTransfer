import Foundation

// MARK: - Widget Data Store

/// Reads and writes health metric snapshots to App Group UserDefaults.
/// Used by both the main app (writes) and widget extension (reads).
final class WidgetDataStore: @unchecked Sendable {

    // MARK: - Constants

    static let appGroupID = "group.com.caseysimon.HealthAppTransfer"
    private static let snapshotsKey = "widget_metric_snapshots"
    private static let insightKey = "widget_insight_snapshot"
    private static let streakDataKey = "widget_streak_data"
    private static let goalProgressKey = "widget_goal_progress"

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

    // MARK: - Insight Write

    func saveInsight(_ snapshot: WidgetInsightSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: Self.insightKey)
    }

    // MARK: - Insight Read

    func loadInsight() -> WidgetInsightSnapshot? {
        guard let data = defaults?.data(forKey: Self.insightKey),
              let snapshot = try? JSONDecoder().decode(WidgetInsightSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }

    // MARK: - Streak Data

    func saveStreakData(_ data: [String: Int]) {
        defaults?.set(data, forKey: Self.streakDataKey)
    }

    func loadStreakData() -> [String: Int] {
        defaults?.dictionary(forKey: Self.streakDataKey) as? [String: Int] ?? [:]
    }

    // MARK: - Goal Progress

    func saveGoalProgress(_ data: [String: Double]) {
        defaults?.set(data, forKey: Self.goalProgressKey)
    }

    func loadGoalProgress() -> [String: Double] {
        defaults?.dictionary(forKey: Self.goalProgressKey) as? [String: Double] ?? [:]
    }
}
