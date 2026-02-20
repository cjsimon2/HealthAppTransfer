import Foundation
import SwiftUI

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {

    // MARK: - Types

    struct MetricCard: Identifiable {
        let dataType: HealthDataType
        let latestValue: String
        let samples: [AggregatedSample]
        let trend: TrendDirection
        var id: String { dataType.rawValue }
    }

    // MARK: - Default Metrics

    /// Sensible defaults for the dashboard when user has no preference set.
    static let defaultMetricTypes: [HealthDataType] = [
        .stepCount,
        .heartRate,
        .activeEnergyBurned,
        .distanceWalkingRunning,
        .restingHeartRate,
        .bodyMass
    ]

    // MARK: - Published State

    @Published var cards: [MetricCard] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Dependencies

    private let healthKitService: HealthKitService
    private let aggregationEngine = AggregationEngine()

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Data Loading

    func loadMetrics(configuredTypes: [HealthDataType]) async {
        isLoading = true
        defer { isLoading = false }

        let typesToLoad = configuredTypes.isEmpty ? Self.defaultMetricTypes : configuredTypes
        let quantityTypes = typesToLoad.filter(\.isQuantityType)

        let range = ChartDateRange.week.defaultDateRange

        var loadedCards: [MetricCard] = []
        for type in quantityTypes {
            do {
                let samples = try await aggregationEngine.aggregate(
                    type: type,
                    operations: [.sum, .average, .min, .max],
                    interval: .daily,
                    from: range.start,
                    to: range.end
                )
                let card = makeCard(for: type, samples: samples)
                loadedCards.append(card)
            } catch {
                // Skip metrics that fail to load — show what we can
                loadedCards.append(MetricCard(
                    dataType: type,
                    latestValue: "—",
                    samples: [],
                    trend: .noData
                ))
            }
        }

        cards = loadedCards
    }

    // MARK: - Helpers

    private func makeCard(for type: HealthDataType, samples: [AggregatedSample]) -> MetricCard {
        let active = samples.filter { $0.count > 0 }
        let latest = latestFormatted(active, unit: samples.first?.unit ?? "")
        let trend = computeTrend(active)
        return MetricCard(dataType: type, latestValue: latest, samples: samples, trend: trend)
    }

    private func latestFormatted(_ active: [AggregatedSample], unit: String) -> String {
        guard let last = active.last else { return "—" }
        let value = last.sum ?? last.average ?? last.latest ?? 0
        return formatValue(value, unit: unit)
    }

    private func computeTrend(_ active: [AggregatedSample]) -> TrendDirection {
        guard active.count >= 2 else { return .noData }
        let recentHalf = active.suffix(active.count / 2)
        let olderHalf = active.prefix(active.count / 2)

        func avg(_ slice: ArraySlice<AggregatedSample>) -> Double {
            let values = slice.map { $0.sum ?? $0.average ?? $0.latest ?? 0 }
            guard !values.isEmpty else { return 0 }
            return values.reduce(0, +) / Double(values.count)
        }

        let diff = avg(recentHalf) - avg(olderHalf)
        let threshold = max(avg(olderHalf) * 0.05, 0.01) // 5% change threshold
        if diff > threshold { return .up }
        if diff < -threshold { return .down }
        return .flat
    }

    private func formatValue(_ value: Double, unit: String) -> String {
        if value == value.rounded() {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }
}
