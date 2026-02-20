import HealthKit
import WidgetKit

// MARK: - Health Metric Entry

struct HealthMetricEntry: TimelineEntry {
    let date: Date
    let metrics: [WidgetMetricSnapshot]
    let configuration: SelectMetricsIntent
}

// MARK: - Health Metric Provider

struct HealthMetricProvider: AppIntentTimelineProvider {

    private let dataStore = WidgetDataStore.shared

    // MARK: - TimelineProvider

    func placeholder(in context: Context) -> HealthMetricEntry {
        HealthMetricEntry(
            date: .now,
            metrics: Self.placeholderMetrics(for: context.family),
            configuration: SelectMetricsIntent()
        )
    }

    func snapshot(for configuration: SelectMetricsIntent, in context: Context) async -> HealthMetricEntry {
        let metrics = resolveMetrics(for: configuration, family: context.family)
        return HealthMetricEntry(date: .now, metrics: metrics, configuration: configuration)
    }

    func timeline(for configuration: SelectMetricsIntent, in context: Context) async -> Timeline<HealthMetricEntry> {
        // Try HealthKit first for fresh data, fall back to cache
        var metrics = await fetchFromHealthKit(for: configuration, family: context.family)
        if metrics.isEmpty {
            metrics = resolveMetrics(for: configuration, family: context.family)
        }

        let entry = HealthMetricEntry(date: .now, metrics: metrics, configuration: configuration)

        // Refresh every 15 minutes (HealthKit widget budget)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // MARK: - Metric Resolution

    private func resolveMetrics(
        for configuration: SelectMetricsIntent,
        family: WidgetFamily
    ) -> [WidgetMetricSnapshot] {
        let allCached = dataStore.loadAll()
        let maxCount = maxMetrics(for: family)

        if let selected = configuration.metrics, !selected.isEmpty {
            let selectedIDs = Set(selected.map(\.id))
            let matched = allCached.filter { selectedIDs.contains($0.metricType) }
            if !matched.isEmpty {
                return Array(matched.prefix(maxCount))
            }
        }

        guard !allCached.isEmpty else {
            return Self.placeholderMetrics(for: family)
        }
        return Array(allCached.prefix(maxCount))
    }

    // MARK: - HealthKit Queries

    private func fetchFromHealthKit(
        for configuration: SelectMetricsIntent,
        family: WidgetFamily
    ) async -> [WidgetMetricSnapshot] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }

        let maxCount = maxMetrics(for: family)
        let targetIDs: [String]

        if let selected = configuration.metrics, !selected.isEmpty {
            targetIDs = Array(selected.map(\.id).prefix(maxCount))
        } else {
            let cached = dataStore.loadAll()
            targetIDs = Array(cached.map(\.metricType).prefix(maxCount))
        }

        guard !targetIDs.isEmpty else { return [] }

        let store = HKHealthStore()
        var results: [WidgetMetricSnapshot] = []

        for metricID in targetIDs {
            guard let dataType = HealthDataType(rawValue: metricID),
                  dataType.isQuantityType else {
                // For non-quantity types, use cached data
                if let cached = dataStore.snapshot(for: metricID) {
                    results.append(cached)
                }
                continue
            }

            if let snapshot = await queryLatestValue(for: dataType, store: store) {
                results.append(snapshot)
            } else if let cached = dataStore.snapshot(for: metricID) {
                results.append(cached)
            }
        }

        return results
    }

    /// Query the latest value for a quantity type from HealthKit.
    private func queryLatestValue(
        for dataType: HealthDataType,
        store: HKHealthStore
    ) async -> WidgetMetricSnapshot? {
        let quantityType = HKQuantityType(dataType.quantityTypeIdentifier)
        let isCumulative = quantityType.aggregationStyle == .cumulative
        let options: HKStatisticsOptions = isCumulative ? .cumulativeSum : .discreteAverage

        // Query today's statistics
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: .now)

        let value: Double? = await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, _ in
                guard let statistics else {
                    continuation.resume(returning: nil)
                    return
                }
                // Use unit string from cached data since we don't have HealthSampleMapper here
                let cached = self.dataStore.snapshot(for: dataType.rawValue)
                let unitString = cached?.unit ?? "count"
                let unit = Self.hkUnit(from: unitString)

                let result = isCumulative
                    ? statistics.sumQuantity()?.doubleValue(for: unit)
                    : statistics.averageQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: result)
            }
            store.execute(query)
        }

        // Use cached sparkline data since we can't efficiently query 7 days in widget context
        let cached = dataStore.snapshot(for: dataType.rawValue)

        return WidgetMetricSnapshot(
            metricType: dataType.rawValue,
            displayName: dataType.displayName,
            iconName: dataType.category.iconName,
            currentValue: value ?? cached?.currentValue,
            unit: cached?.unit ?? "",
            sparklineValues: cached?.sparklineValues ?? [],
            lastUpdated: .now
        )
    }

    // MARK: - Helpers

    private func maxMetrics(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall: return 1
        case .systemMedium: return 3
        case .systemLarge: return 6
        default: return 1
        }
    }

    /// Convert a unit string back to HKUnit for HealthKit queries.
    /// Handles common unit strings from the app's unit mapping.
    static func hkUnit(from unitString: String) -> HKUnit {
        switch unitString {
        case "count": return .count()
        case "count/min": return HKUnit.count().unitDivided(by: .minute())
        case "kcal": return .kilocalorie()
        case "m": return .meter()
        case "km": return .meterUnit(with: .kilo)
        case "mi": return .mile()
        case "min": return .minute()
        case "s": return .second()
        case "ms": return .secondUnit(with: .milli)
        case "kg": return .gramUnit(with: .kilo)
        case "lb": return .pound()
        case "cm": return .meterUnit(with: .centi)
        case "%": return .percent()
        case "°C": return .degreeCelsius()
        case "°F": return .degreeFahrenheit()
        case "mmHg": return .millimeterOfMercury()
        case "mg/dL": return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        case "W": return .watt()
        case "m/s": return HKUnit.meter().unitDivided(by: .second())
        case "dBASPL": return .decibelAWeightedSoundPressureLevel()
        case "mL": return .literUnit(with: .milli)
        case "L": return .liter()
        case "g": return .gram()
        case "IU": return .internationalUnit()
        default: return .count()
        }
    }

    // MARK: - Placeholder Data

    static func placeholderMetrics(for family: WidgetFamily) -> [WidgetMetricSnapshot] {
        let all: [WidgetMetricSnapshot] = [
            WidgetMetricSnapshot(
                metricType: "stepCount",
                displayName: "Steps",
                iconName: "flame.fill",
                currentValue: 8432,
                unit: "steps",
                sparklineValues: [5200, 7800, 6300, 9100, 8400, 7200, 8432],
                lastUpdated: .now
            ),
            WidgetMetricSnapshot(
                metricType: "heartRate",
                displayName: "Heart Rate",
                iconName: "heart.fill",
                currentValue: 72,
                unit: "bpm",
                sparklineValues: [68, 71, 74, 69, 73, 70, 72],
                lastUpdated: .now
            ),
            WidgetMetricSnapshot(
                metricType: "activeEnergyBurned",
                displayName: "Active Energy",
                iconName: "flame.fill",
                currentValue: 485,
                unit: "kcal",
                sparklineValues: [320, 510, 430, 580, 410, 460, 485],
                lastUpdated: .now
            ),
            WidgetMetricSnapshot(
                metricType: "oxygenSaturation",
                displayName: "Blood Oxygen",
                iconName: "waveform.path.ecg",
                currentValue: 98,
                unit: "%",
                sparklineValues: [97, 98, 97, 99, 98, 97, 98],
                lastUpdated: .now
            ),
            WidgetMetricSnapshot(
                metricType: "bodyMass",
                displayName: "Weight",
                iconName: "figure",
                currentValue: 75.2,
                unit: "kg",
                sparklineValues: [76.1, 75.8, 75.5, 75.9, 75.4, 75.3, 75.2],
                lastUpdated: .now
            ),
            WidgetMetricSnapshot(
                metricType: "restingHeartRate",
                displayName: "Resting HR",
                iconName: "heart.fill",
                currentValue: 62,
                unit: "bpm",
                sparklineValues: [64, 63, 65, 62, 63, 61, 62],
                lastUpdated: .now
            ),
        ]

        let count: Int
        switch family {
        case .systemSmall: count = 1
        case .systemMedium: count = 3
        case .systemLarge: count = 6
        default: count = 1
        }
        return Array(all.prefix(count))
    }
}
