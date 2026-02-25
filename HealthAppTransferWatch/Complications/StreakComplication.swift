import WidgetKit
import SwiftUI

// MARK: - Streak Complication

/// watchOS complication showing the current best streak day count.
struct StreakComplication: Widget {
    let kind = "StreakComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakComplicationView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Shows your current activity streak.")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

// MARK: - Timeline Entry

struct StreakTimelineEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let metricName: String
}

// MARK: - Timeline Provider

struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakTimelineEntry {
        StreakTimelineEntry(date: .now, streakDays: 7, metricName: "Steps")
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakTimelineEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakTimelineEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> StreakTimelineEntry {
        let streakData = WidgetDataStore.shared.loadStreakData()
        let best = streakData.max(by: { $0.value < $1.value })
        let metricName = best?.key
            .replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "") ?? "Activity"
        return StreakTimelineEntry(
            date: .now,
            streakDays: best?.value ?? 0,
            metricName: metricName
        )
    }
}

// MARK: - Complication View

struct StreakComplicationView: View {
    let entry: StreakTimelineEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "flame")
                    .font(.caption)
                Text("\(entry.streakDays)")
                    .font(.title3.bold())
            }
        }
        .widgetLabel("\(entry.streakDays)d streak")
    }
}
