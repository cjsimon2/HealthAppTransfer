import SwiftUI
import WidgetKit

// MARK: - Insight Entry

struct InsightEntry: TimelineEntry {
    let date: Date
    let insight: WidgetInsightSnapshot?
}

// MARK: - Insight of Day Provider

struct InsightOfDayProvider: TimelineProvider {

    private let dataStore = WidgetDataStore.shared

    func placeholder(in context: Context) -> InsightEntry {
        InsightEntry(date: .now, insight: Self.placeholderInsight)
    }

    func getSnapshot(in context: Context, completion: @escaping (InsightEntry) -> Void) {
        let insight = dataStore.loadInsight()
        completion(InsightEntry(date: .now, insight: insight ?? Self.placeholderInsight))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InsightEntry>) -> Void) {
        let insight = dataStore.loadInsight()
        let entry = InsightEntry(date: .now, insight: insight)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Placeholder

    static let placeholderInsight = WidgetInsightSnapshot(
        id: "placeholder",
        iconName: "flame",
        metricName: "Steps",
        message: "5-day streak! Keep it going",
        categoryIconName: "flame.fill",
        lastUpdated: .now
    )
}

// MARK: - Insight of Day Widget

struct InsightOfDayWidget: Widget {
    let kind = "InsightOfDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: InsightOfDayProvider()
        ) { entry in
            InsightOfDayEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Insight of the Day")
        .description("Your latest health insight at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
