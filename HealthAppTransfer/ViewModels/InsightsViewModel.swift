import Foundation
import SwiftData

// MARK: - Insight Item

/// A single auto-generated insight about the user's health data.
enum InsightItem: Identifiable {
    case weeklySummary(type: HealthDataType, percentChange: Double, direction: String)
    case personalRecord(type: HealthDataType, value: Double, unit: String)
    case dayOfWeekPattern(type: HealthDataType, dayName: String)
    case anomaly(type: HealthDataType, metric: String, direction: String)

    var id: String {
        switch self {
        case .weeklySummary(let type, _, _): return "weekly.\(type.rawValue)"
        case .personalRecord(let type, _, _): return "record.\(type.rawValue)"
        case .dayOfWeekPattern(let type, _): return "pattern.\(type.rawValue)"
        case .anomaly(let type, _, _): return "anomaly.\(type.rawValue)"
        }
    }

    var dataType: HealthDataType {
        switch self {
        case .weeklySummary(let type, _, _): return type
        case .personalRecord(let type, _, _): return type
        case .dayOfWeekPattern(let type, _): return type
        case .anomaly(let type, _, _): return type
        }
    }
}

// MARK: - Correlation Result

/// Result of a Pearson correlation analysis between two health metrics.
struct CorrelationResult {
    let typeA: HealthDataType
    let typeB: HealthDataType
    let points: [(x: Double, y: Double, date: Date)]
    let rValue: Double
    let strengthLabel: String
}

// MARK: - Correlation Data Point

/// A single scatter plot point with date context — Identifiable for SwiftUI iteration.
struct CorrelationDataPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let date: Date
}

// MARK: - Insights ViewModel

@MainActor
class InsightsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var insights: [InsightItem] = []
    @Published var isLoadingInsights = false
    @Published var correlationResult: CorrelationResult?
    @Published var isLoadingCorrelation = false
    @Published var selectedMetricA: HealthDataType = .stepCount
    @Published var selectedMetricB: HealthDataType = .heartRate

    // MARK: - Constants

    static let defaultInsightTypes: [HealthDataType] = [
        .stepCount,
        .heartRate,
        .activeEnergyBurned,
        .distanceWalkingRunning,
        .restingHeartRate,
        .bodyMass
    ]

    static let suggestedPairs: [(HealthDataType, HealthDataType)] = [
        (.stepCount, .heartRate),
        (.stepCount, .activeEnergyBurned),
        (.bodyMass, .dietaryEnergyConsumed),
        (.activeEnergyBurned, .distanceWalkingRunning),
        (.restingHeartRate, .stepCount)
    ]

    // MARK: - Dependencies

    private let healthKitService: HealthKitService
    private let aggregationEngine: AggregationEngine

    init(healthKitService: HealthKitService, aggregationEngine: AggregationEngine = AggregationEngine()) {
        self.healthKitService = healthKitService
        self.aggregationEngine = aggregationEngine
    }

    // MARK: - Load Insights

    func loadInsights(modelContext: ModelContext? = nil) async {
        isLoadingInsights = true
        defer { isLoadingInsights = false }

        var results: [InsightItem] = []

        for type in Self.defaultInsightTypes {
            let samples = await fetchDailyData(type: type, days: 30, modelContext: modelContext)
            let active = samples.filter { $0.count > 0 }
            guard active.count >= 7 else { continue }

            if let insight = weeklySummary(type: type, samples: active) {
                results.append(insight)
            }
            if let insight = personalRecord(type: type, samples: active) {
                results.append(insight)
            }
            if let insight = dayOfWeekPattern(type: type, samples: active) {
                results.append(insight)
            }
            if let insight = anomalyDetection(type: type, samples: active) {
                results.append(insight)
            }
        }

        insights = results
    }

    // MARK: - Load Correlation

    func loadCorrelation(modelContext: ModelContext? = nil) async {
        isLoadingCorrelation = true
        defer { isLoadingCorrelation = false }

        let samplesA = await fetchDailyData(type: selectedMetricA, days: 90, modelContext: modelContext)
        let samplesB = await fetchDailyData(type: selectedMetricB, days: 90, modelContext: modelContext)

        let activeA = samplesA.filter { $0.count > 0 }
        let activeB = samplesB.filter { $0.count > 0 }

        // Join on matching dates (same calendar day)
        let calendar = Calendar.current
        var bByDay: [DateComponents: AggregatedSample] = [:]
        for sample in activeB {
            let comps = calendar.dateComponents([.year, .month, .day], from: sample.startDate)
            bByDay[comps] = sample
        }

        var points: [(x: Double, y: Double, date: Date)] = []
        for sampleA in activeA {
            let comps = calendar.dateComponents([.year, .month, .day], from: sampleA.startDate)
            guard let sampleB = bByDay[comps] else { continue }
            let xVal = sampleValue(sampleA)
            let yVal = sampleValue(sampleB)
            points.append((x: xVal, y: yVal, date: sampleA.startDate))
        }

        guard points.count >= 3 else {
            correlationResult = CorrelationResult(
                typeA: selectedMetricA,
                typeB: selectedMetricB,
                points: [],
                rValue: 0,
                strengthLabel: "Insufficient data"
            )
            return
        }

        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let r = pearsonCorrelation(xs: xs, ys: ys)

        correlationResult = CorrelationResult(
            typeA: selectedMetricA,
            typeB: selectedMetricB,
            points: points,
            rValue: r,
            strengthLabel: correlationStrength(r)
        )
    }

    // MARK: - Data Fetching

    private func fetchDailyData(type: HealthDataType, days: Int, modelContext: ModelContext?) async -> [AggregatedSample] {
        guard type.isQuantityType else { return [] }

        let calendar = Calendar.current
        let end = Date()
        guard let start = calendar.date(byAdding: .day, value: -days, to: end) else { return [] }

        if !HealthKitService.isAvailable, let modelContext {
            return SyncedHealthSample.aggregate(
                type: type,
                interval: .daily,
                from: start,
                to: end,
                modelContext: modelContext
            )
        }

        do {
            return try await aggregationEngine.aggregate(
                type: type,
                operations: [.sum, .average, .min, .max],
                interval: .daily,
                from: start,
                to: end
            )
        } catch {
            return []
        }
    }

    // MARK: - Insight Generators

    private func weeklySummary(type: HealthDataType, samples: [AggregatedSample]) -> InsightItem? {
        guard samples.count >= 14 else { return nil }

        let thisWeek = samples.suffix(7)
        let lastWeek = samples.suffix(14).prefix(7)

        let thisSum = thisWeek.reduce(0.0) { $0 + sampleValue($1) }
        let lastSum = lastWeek.reduce(0.0) { $0 + sampleValue($1) }

        guard lastSum > 0 else { return nil }

        let percentChange = ((thisSum - lastSum) / lastSum) * 100
        guard abs(percentChange) >= 5 else { return nil }

        let direction = percentChange > 0 ? "up" : "down"
        return .weeklySummary(type: type, percentChange: percentChange, direction: direction)
    }

    private func personalRecord(type: HealthDataType, samples: [AggregatedSample]) -> InsightItem? {
        guard samples.count >= 7 else { return nil }

        let values = samples.map { sampleValue($0) }
        guard let maxValue = values.max(), maxValue > 0 else { return nil }

        // Check if the max falls in the most recent 7 days
        let recentValues = samples.suffix(7).map { sampleValue($0) }
        guard let recentMax = recentValues.max(), recentMax == maxValue else { return nil }

        let unit = samples.first?.unit ?? ""
        return .personalRecord(type: type, value: maxValue, unit: unit)
    }

    private func dayOfWeekPattern(type: HealthDataType, samples: [AggregatedSample]) -> InsightItem? {
        guard samples.count >= 14 else { return nil }

        let calendar = Calendar.current
        var dayTotals: [Int: [Double]] = [:]

        for sample in samples {
            let weekday = calendar.component(.weekday, from: sample.startDate)
            dayTotals[weekday, default: []].append(sampleValue(sample))
        }

        let dayAverages = dayTotals.compactMapValues { values -> Double? in
            guard !values.isEmpty else { return nil }
            return values.reduce(0, +) / Double(values.count)
        }

        guard dayAverages.count >= 3 else { return nil }

        let allAverages = dayAverages.values.map { $0 }
        let mean = allAverages.reduce(0, +) / Double(allAverages.count)
        guard mean > 0 else { return nil }

        guard let (topDay, topAvg) = dayAverages.max(by: { $0.value < $1.value }) else { return nil }
        let aboveMean = (topAvg - mean) / mean
        guard aboveMean > 0.15 else { return nil }

        let dayName = calendar.weekdaySymbols[topDay - 1]
        return .dayOfWeekPattern(type: type, dayName: dayName + "s")
    }

    private func anomalyDetection(type: HealthDataType, samples: [AggregatedSample]) -> InsightItem? {
        guard samples.count >= 14 else { return nil }

        // Use all but the last day as baseline
        let baseline = Array(samples.dropLast())
        guard let today = samples.last else { return nil }

        let values = baseline.map { sampleValue($0) }.sorted()
        guard values.count >= 4 else { return nil }

        let q1 = values[values.count / 4]
        let q3 = values[(values.count * 3) / 4]
        let iqr = q3 - q1
        guard iqr > 0 else { return nil }

        let lower = q1 - 1.5 * iqr
        let upper = q3 + 1.5 * iqr
        let todayValue = sampleValue(today)

        if todayValue > upper {
            return .anomaly(type: type, metric: type.displayName, direction: "unusually high")
        } else if todayValue < lower {
            return .anomaly(type: type, metric: type.displayName, direction: "unusually low")
        }

        return nil
    }

    // MARK: - Statistical Functions

    func pearsonCorrelation(xs: [Double], ys: [Double]) -> Double {
        let n = Double(xs.count)
        guard n > 0, xs.count == ys.count else { return 0 }

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).reduce(0.0) { $0 + $1.0 * $1.1 }
        let sumX2 = xs.reduce(0.0) { $0 + $1 * $1 }
        let sumY2 = ys.reduce(0.0) { $0 + $1 * $1 }

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }

    func correlationStrength(_ r: Double) -> String {
        let absR = abs(r)
        if absR < 0.3 { return "Weak" }
        if absR < 0.7 { return "Moderate" }
        return "Strong"
    }

    // MARK: - Helpers

    private func sampleValue(_ sample: AggregatedSample) -> Double {
        sample.sum ?? sample.average ?? sample.latest ?? 0
    }
}
