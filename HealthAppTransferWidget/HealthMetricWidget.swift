import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Metric Entity

/// An AppEntity representing a selectable health metric for widget configuration.
struct MetricEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Health Metric")
    static var defaultQuery = MetricEntityQuery()

    var id: String
    var displayName: String
    var iconName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            image: .init(systemName: iconName)
        )
    }
}

// MARK: - Metric Entity Query

struct MetricEntityQuery: EntityQuery {

    func entities(for identifiers: [String]) async throws -> [MetricEntity] {
        let all = availableMetrics()
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [MetricEntity] {
        availableMetrics()
    }

    func defaultResult() async -> MetricEntity? {
        availableMetrics().first
    }

    // MARK: - Helpers

    private func availableMetrics() -> [MetricEntity] {
        let cached = WidgetDataStore.shared.loadAll()
        if !cached.isEmpty {
            return cached.map {
                MetricEntity(id: $0.metricType, displayName: $0.displayName, iconName: $0.iconName)
            }
        }
        return Self.defaults
    }

    /// Fallback metrics when no cached data exists yet.
    static let defaults: [MetricEntity] = [
        MetricEntity(id: "stepCount", displayName: "Step Count", iconName: "flame.fill"),
        MetricEntity(id: "heartRate", displayName: "Heart Rate", iconName: "heart.fill"),
        MetricEntity(id: "activeEnergyBurned", displayName: "Active Energy", iconName: "flame.fill"),
        MetricEntity(id: "restingHeartRate", displayName: "Resting Heart Rate", iconName: "heart.fill"),
        MetricEntity(id: "oxygenSaturation", displayName: "Blood Oxygen", iconName: "waveform.path.ecg"),
        MetricEntity(id: "bodyMass", displayName: "Weight", iconName: "figure"),
        MetricEntity(id: "sleepAnalysis", displayName: "Sleep", iconName: "bed.double.fill"),
        MetricEntity(id: "vo2Max", displayName: "VO2 Max", iconName: "sportscourt.fill"),
    ]
}

// MARK: - Widget Configuration Intent

struct SelectMetricsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Health Metrics"
    static var description = IntentDescription("Choose which health metrics to display.")

    @Parameter(title: "Metrics")
    var metrics: [MetricEntity]?
}

// MARK: - Health Metric Widget

struct HealthMetricWidget: Widget {
    let kind = "HealthMetricWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectMetricsIntent.self,
            provider: HealthMetricProvider()
        ) { entry in
            HealthWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Health Metrics")
        .description("View your health data at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
