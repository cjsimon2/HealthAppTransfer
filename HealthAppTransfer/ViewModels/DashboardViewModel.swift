import Foundation
import SwiftData
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
    private let aggregationEngine: AggregationEngine

    init(healthKitService: HealthKitService, aggregationEngine: AggregationEngine = AggregationEngine()) {
        self.healthKitService = healthKitService
        self.aggregationEngine = aggregationEngine
    }

    // MARK: - Data Loading

    func loadMetrics(configuredTypes: [HealthDataType], modelContext: ModelContext? = nil) async {
        #if os(macOS)
        if let modelContext {
            await loadMetricsFromStore(configuredTypes: configuredTypes, modelContext: modelContext)
            return
        }
        #endif

        await loadMetricsFromHealthKit(configuredTypes: configuredTypes)
    }

    // MARK: - HealthKit Path (iOS)

    private func loadMetricsFromHealthKit(configuredTypes: [HealthDataType]) async {
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

    // MARK: - SwiftData Path (macOS)

    #if os(macOS)
    private func loadMetricsFromStore(configuredTypes: [HealthDataType], modelContext: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        let typesToLoad = configuredTypes.isEmpty ? Self.defaultMetricTypes : configuredTypes
        let quantityTypes = typesToLoad.filter(\.isQuantityType)

        let range = ChartDateRange.week.defaultDateRange

        var loadedCards: [MetricCard] = []
        for type in quantityTypes {
            let samples = aggregateFromStore(
                type: type,
                from: range.start,
                to: range.end,
                modelContext: modelContext
            )
            let card = makeCard(for: type, samples: samples)
            loadedCards.append(card)
        }

        cards = loadedCards
    }

    /// Aggregate SyncedHealthSample records by day for a given type.
    private func aggregateFromStore(
        type: HealthDataType,
        from startDate: Date,
        to endDate: Date,
        modelContext: ModelContext
    ) -> [AggregatedSample] {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<SyncedHealthSample>(
            predicate: #Predicate { sample in
                sample.typeRawValue == typeRaw &&
                sample.startDate >= startDate &&
                sample.startDate <= endDate
            },
            sortBy: [SortDescriptor(\.startDate)]
        )

        let samples = (try? modelContext.fetch(descriptor)) ?? []

        // Group by day
        let calendar = Calendar.current
        var dailyGroups: [Date: [SyncedHealthSample]] = [:]
        for sample in samples {
            let dayStart = calendar.startOfDay(for: sample.startDate)
            dailyGroups[dayStart, default: []].append(sample)
        }

        // Generate all days in range
        var results: [AggregatedSample] = []
        var currentDay = calendar.startOfDay(for: startDate)

        while currentDay <= endDate {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: currentDay)!
            let daySamples = dailyGroups[currentDay] ?? []
            let values = daySamples.compactMap(\.value)
            let unit = daySamples.first?.unit ?? ""

            results.append(AggregatedSample(
                startDate: currentDay,
                endDate: dayEnd,
                sum: values.isEmpty ? nil : values.reduce(0, +),
                average: values.isEmpty ? nil : values.reduce(0, +) / Double(values.count),
                min: values.min(),
                max: values.max(),
                latest: values.last,
                count: values.isEmpty ? 0 : 1,
                unit: unit
            ))

            currentDay = dayEnd
        }

        return results
    }
    #endif

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
