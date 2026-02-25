import Foundation
import SwiftData

// MARK: - Insight Item

/// A single auto-generated insight about the user's health data.
enum InsightItem: Identifiable {
    case weeklySummary(type: HealthDataType, percentChange: Double, direction: String)
    case personalRecord(type: HealthDataType, value: Double, unit: String)
    case dayOfWeekPattern(type: HealthDataType, dayName: String)
    case anomaly(type: HealthDataType, metric: String, direction: String)
    case streak(type: HealthDataType, days: Int, threshold: Double, unit: String, sparkline: [Double])
    case goalProgress(type: HealthDataType, current: Double, goal: Double, unit: String, sparkline: [Double])

    var id: String {
        switch self {
        case .weeklySummary(let type, _, _): return "weekly.\(type.rawValue)"
        case .personalRecord(let type, _, _): return "record.\(type.rawValue)"
        case .dayOfWeekPattern(let type, _): return "pattern.\(type.rawValue)"
        case .anomaly(let type, _, _): return "anomaly.\(type.rawValue)"
        case .streak(let type, _, _, _, _): return "streak.\(type.rawValue)"
        case .goalProgress(let type, _, _, _, _): return "goal.\(type.rawValue)"
        }
    }

    var dataType: HealthDataType {
        switch self {
        case .weeklySummary(let type, _, _): return type
        case .personalRecord(let type, _, _): return type
        case .dayOfWeekPattern(let type, _): return type
        case .anomaly(let type, _, _): return type
        case .streak(let type, _, _, _, _): return type
        case .goalProgress(let type, _, _, _, _): return type
        }
    }

    var iconName: String {
        switch self {
        case .weeklySummary(_, let pct, _): return pct > 0 ? "arrow.up.right" : "arrow.down.right"
        case .personalRecord: return "trophy"
        case .dayOfWeekPattern: return "calendar"
        case .anomaly: return "exclamationmark.triangle"
        case .streak: return "flame"
        case .goalProgress: return "target"
        }
    }

    var message: String {
        switch self {
        case .weeklySummary(let type, let pct, let dir):
            let p = Int(abs(pct))
            return "\(type.displayName) \(dir) \(p)% vs last week"
        case .personalRecord(let type, _, _):
            return "New highest \(type.displayName.lowercased()) this month!"
        case .dayOfWeekPattern(_, let dayName):
            return "Most active on \(dayName)"
        case .anomaly(_, let metric, let direction):
            return "\(metric) \(direction) today"
        case .streak(_, let days, _, _, _):
            return "\(days)-day streak! Keep it going"
        case .goalProgress(_, let current, let goal, let unit, _):
            let pct = Int((current / goal) * 100)
            let remaining = Int(goal - current)
            return "\(pct)% to goal — \(remaining.formatted()) \(unit) to go"
        }
    }

    var sparkline: [Double]? {
        switch self {
        case .streak(_, _, _, _, let data): return data
        case .goalProgress(_, _, _, _, let data): return data
        default: return nil
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
    @Published var favoritePairs: Set<String> = []

    // MARK: - Constants

    static let defaultInsightTypes: [HealthDataType] = [
        .stepCount,
        .heartRate,
        .activeEnergyBurned,
        .distanceWalkingRunning,
        .restingHeartRate,
        .bodyMass,
        .appleExerciseTime
    ]

    static let streakThresholds: [HealthDataType: (threshold: Double, unit: String)] = [
        .stepCount: (10_000, "steps"),
        .activeEnergyBurned: (500, "kcal"),
        .distanceWalkingRunning: (5_000, "m"),
        .appleExerciseTime: (30, "min"),
    ]

    static let dailyGoals: [HealthDataType: (goal: Double, unit: String)] = [
        .stepCount: (10_000, "steps"),
        .activeEnergyBurned: (500, "kcal"),
        .distanceWalkingRunning: (5_000, "m"),
        .appleExerciseTime: (30, "min"),
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

    // MARK: - Goal Resolution

    func resolvedGoal(for type: HealthDataType, preferences: UserPreferences?) -> (goal: Double, unit: String)? {
        if let prefs = preferences, let custom = prefs.customGoals[type.rawValue], custom > 0 {
            let unit = Self.dailyGoals[type]?.unit ?? ""
            return (custom, unit)
        }
        return Self.dailyGoals[type]
    }

    func resolvedStreakThreshold(for type: HealthDataType, preferences: UserPreferences?) -> (threshold: Double, unit: String)? {
        if let prefs = preferences, let custom = prefs.customStreakThresholds[type.rawValue], custom > 0 {
            let unit = Self.streakThresholds[type]?.unit ?? ""
            return (custom, unit)
        }
        return Self.streakThresholds[type]
    }

    // MARK: - Load Insights

    func loadInsights(modelContext: ModelContext? = nil) async {
        isLoadingInsights = true
        defer { isLoadingInsights = false }

        // Fetch user preferences for custom goals
        var preferences: UserPreferences?
        if let modelContext {
            let descriptor = FetchDescriptor<UserPreferences>()
            preferences = try? modelContext.fetch(descriptor).first
        }

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
            if let insight = streakDetection(type: type, samples: active, preferences: preferences) {
                results.append(insight)
            }
            if let insight = goalProgress(type: type, samples: active, preferences: preferences) {
                results.append(insight)
            }
        }

        insights = results

        // Push top insight to widget
        if let top = results.first {
            let snapshot = WidgetInsightSnapshot(
                id: top.id,
                iconName: top.iconName,
                metricName: top.dataType.displayName,
                message: top.message,
                categoryIconName: top.dataType.category.iconName,
                lastUpdated: Date()
            )
            WidgetDataStore.shared.saveInsight(snapshot)
        }

        // Push streak/goal data to widget for watchOS
        pushWidgetData(from: results)

        // Push to watch if connected
        #if canImport(WatchConnectivity)
        PhoneSessionDelegate.shared.pushDataToWatch()
        #endif

        // Schedule notifications if enabled
        if let preferences, let modelContext {
            await scheduleNotificationsIfNeeded(insights: results, preferences: preferences, modelContext: modelContext)
        }
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
        let strength = correlationStrength(r)

        correlationResult = CorrelationResult(
            typeA: selectedMetricA,
            typeB: selectedMetricB,
            points: points,
            rValue: r,
            strengthLabel: strength
        )

        // Save correlation record for history
        if let modelContext {
            saveCorrelationRecord(
                typeA: selectedMetricA,
                typeB: selectedMetricB,
                rValue: r,
                pointCount: points.count,
                strengthLabel: strength,
                modelContext: modelContext
            )
        }
    }

    // MARK: - Correlation History

    private func saveCorrelationRecord(
        typeA: HealthDataType,
        typeB: HealthDataType,
        rValue: Double,
        pointCount: Int,
        strengthLabel: String,
        modelContext: ModelContext
    ) {
        // Deduplicate: skip if same-day record exists for this pair
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        let typeARaw = typeA.rawValue
        let typeBRaw = typeB.rawValue

        var descriptor = FetchDescriptor<CorrelationRecord>(
            predicate: #Predicate<CorrelationRecord> {
                $0.typeARaw == typeARaw &&
                $0.typeBRaw == typeBRaw &&
                $0.date >= todayStart &&
                $0.date < tomorrowStart
            }
        )
        descriptor.fetchLimit = 1

        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let record = CorrelationRecord(
            typeARaw: typeARaw,
            typeBRaw: typeBRaw,
            rValue: rValue,
            pointCount: pointCount,
            date: Date(),
            strengthLabel: strengthLabel
        )
        modelContext.insert(record)
    }

    // MARK: - Favorites

    func loadFavorites(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserPreferences>()
        guard let prefs = try? modelContext.fetch(descriptor).first else { return }
        favoritePairs = Set(prefs.favoriteCorrelationPairs)
    }

    func toggleFavorite(typeA: HealthDataType, typeB: HealthDataType, modelContext: ModelContext) {
        let key = pairKey(typeA: typeA, typeB: typeB)
        if favoritePairs.contains(key) {
            favoritePairs.remove(key)
        } else {
            favoritePairs.insert(key)
        }

        let descriptor = FetchDescriptor<UserPreferences>()
        if let prefs = try? modelContext.fetch(descriptor).first {
            prefs.favoriteCorrelationPairs = Array(favoritePairs)
            prefs.updatedAt = Date()
        }
    }

    func isFavorite(typeA: HealthDataType, typeB: HealthDataType) -> Bool {
        favoritePairs.contains(pairKey(typeA: typeA, typeB: typeB))
    }

    func orderedSuggestedPairs() -> [(HealthDataType, HealthDataType)] {
        Self.suggestedPairs.sorted { a, b in
            let aFav = isFavorite(typeA: a.0, typeB: a.1)
            let bFav = isFavorite(typeA: b.0, typeB: b.1)
            if aFav != bFav { return aFav }
            return false
        }
    }

    private func pairKey(typeA: HealthDataType, typeB: HealthDataType) -> String {
        "\(typeA.rawValue)|\(typeB.rawValue)"
    }

    // MARK: - Widget Data Push

    private func pushWidgetData(from insights: [InsightItem]) {
        var streakData: [String: Int] = [:]
        var goalData: [String: Double] = [:]

        for insight in insights {
            switch insight {
            case .streak(let type, let days, _, _, _):
                streakData[type.rawValue] = days
            case .goalProgress(let type, let current, let goal, _, _):
                goalData[type.rawValue] = goal > 0 ? current / goal : 0
            default:
                break
            }
        }

        if !streakData.isEmpty {
            WidgetDataStore.shared.saveStreakData(streakData)
        }
        if !goalData.isEmpty {
            WidgetDataStore.shared.saveGoalProgress(goalData)
        }
    }

    // MARK: - Notifications

    private func scheduleNotificationsIfNeeded(
        insights: [InsightItem],
        preferences: UserPreferences,
        modelContext: ModelContext
    ) async {
        guard preferences.notificationsEnabled else { return }

        for insight in insights {
            switch insight {
            case .streak(let type, let days, _, _, let sparkline) where preferences.streakAlertsEnabled:
                // Alert if most recent day has zero activity (streak at risk)
                if let lastValue = sparkline.last, lastValue == 0 {
                    await NotificationService.shared.scheduleStreakAlert(type: type, streakDays: days)
                }
            case .goalProgress(let type, let current, let goal, let unit, _) where preferences.goalAlertsEnabled:
                // Alert if >= 90% complete
                if goal > 0, (current / goal) >= 0.9 {
                    await NotificationService.shared.scheduleGoalNearlyMet(
                        type: type, current: current, goal: goal, unit: unit
                    )
                }
            default:
                break
            }
        }
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

    private func streakDetection(type: HealthDataType, samples: [AggregatedSample], preferences: UserPreferences? = nil) -> InsightItem? {
        guard let config = resolvedStreakThreshold(for: type, preferences: preferences) else { return nil }

        // Sort by date descending so we walk backwards from most recent
        let sorted = samples.sorted { $0.startDate > $1.startDate }
        var streakDays = 0

        for sample in sorted {
            if sampleValue(sample) >= config.threshold {
                streakDays += 1
            } else {
                break
            }
        }

        guard streakDays >= 3 else { return nil }

        // Extract last 7 daily values for sparkline
        let sparkline = samples.suffix(7).map { sampleValue($0) }

        return .streak(type: type, days: streakDays, threshold: config.threshold, unit: config.unit, sparkline: sparkline)
    }

    private func goalProgress(type: HealthDataType, samples: [AggregatedSample], preferences: UserPreferences? = nil) -> InsightItem? {
        guard let config = resolvedGoal(for: type, preferences: preferences) else { return nil }
        guard let today = samples.sorted(by: { $0.startDate < $1.startDate }).last else { return nil }

        let current = sampleValue(today)
        let progress = current / config.goal

        // Show if 10%-99% complete (at/above goal handled by streak)
        guard progress >= 0.10, progress < 1.0 else { return nil }

        // Extract last 7 daily values for sparkline
        let sparkline = samples.suffix(7).map { sampleValue($0) }

        return .goalProgress(type: type, current: current, goal: config.goal, unit: config.unit, sparkline: sparkline)
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
