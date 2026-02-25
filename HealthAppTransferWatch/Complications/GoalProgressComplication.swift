import WidgetKit
import SwiftUI

// MARK: - Goal Progress Complication

/// watchOS complication showing a progress ring toward the daily goal.
struct GoalProgressComplication: Widget {
    let kind = "GoalProgressComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalTimelineProvider()) { entry in
            GoalComplicationView(entry: entry)
        }
        .configurationDisplayName("Goal Progress")
        .description("Shows progress toward your daily health goal.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Timeline Entry

struct GoalTimelineEntry: TimelineEntry {
    let date: Date
    let progress: Double
    let metricName: String
}

// MARK: - Timeline Provider

struct GoalTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalTimelineEntry {
        GoalTimelineEntry(date: .now, progress: 0.65, metricName: "Steps")
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalTimelineEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalTimelineEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> GoalTimelineEntry {
        let goalData = WidgetDataStore.shared.loadGoalProgress()
        let best = goalData.max(by: { $0.value < $1.value })
        let metricName = best?.key
            .replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "") ?? "Activity"
        return GoalTimelineEntry(
            date: .now,
            progress: min(best?.value ?? 0, 1.0),
            metricName: metricName
        )
    }
}

// MARK: - Complication View

struct GoalComplicationView: View {
    let entry: GoalTimelineEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Gauge(value: entry.progress) {
                Image(systemName: "target")
            } currentValueLabel: {
                Text("\(Int(entry.progress * 100))%")
                    .font(.caption2)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.green)
        }
        .widgetLabel("\(Int(entry.progress * 100))% \(entry.metricName)")
    }
}
