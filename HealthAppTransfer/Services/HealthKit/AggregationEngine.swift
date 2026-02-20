import Foundation
import HealthKit

// MARK: - Aggregation Engine

/// Computes statistical aggregates over configurable time intervals using HealthKit-native queries.
/// Only quantity types are supported (HKStatisticsCollectionQuery requirement).
actor AggregationEngine {

    // MARK: - Properties

    private let store: any HealthStoreProtocol

    init(store: any HealthStoreProtocol = HKHealthStore()) {
        self.store = store
    }

    // MARK: - Aggregation

    /// Aggregate a quantity type over a date range at the specified interval.
    func aggregate(
        type: HealthDataType,
        operations: Set<AggregationOperation>,
        interval: AggregationInterval,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [AggregatedSample] {
        guard type.isQuantityType else {
            throw AggregationError.unsupportedType(type)
        }

        let quantityType = HKQuantityType(type.quantityTypeIdentifier)
        let isCumulative = quantityType.aggregationStyle == .cumulative
        let options = Self.statisticsOptions(for: operations, isCumulative: isCumulative)
        let unit = HealthSampleMapper.preferredUnit(for: type)
        let anchor = Self.anchorDate(for: interval, relativeTo: startDate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        let store = self.store
        return try await store.fetchAggregatedStatistics(
            for: quantityType,
            unit: unit,
            options: options,
            anchorDate: anchor,
            intervalComponents: interval.dateComponents,
            predicate: predicate,
            enumerateFrom: startDate,
            to: endDate
        )
    }

    // MARK: - Statistics Options

    /// Map aggregation operations to HKStatisticsOptions, respecting cumulative vs discrete rules.
    /// Operations incompatible with the type's aggregation style are silently skipped.
    static func statisticsOptions(
        for operations: Set<AggregationOperation>,
        isCumulative: Bool
    ) -> HKStatisticsOptions {
        var options: HKStatisticsOptions = []

        for op in operations {
            switch (op, isCumulative) {
            case (.sum, true):
                options.insert(.cumulativeSum)
            case (.average, false):
                options.insert(.discreteAverage)
            case (.min, false):
                options.insert(.discreteMin)
            case (.max, false):
                options.insert(.discreteMax)
            case (.latest, _):
                options.insert(.mostRecent)
            default:
                break
            }
        }

        // Ensure at least one option for a valid query
        if options.isEmpty {
            options = isCumulative ? .cumulativeSum : .discreteAverage
        }

        return options
    }

    // MARK: - Anchor Date

    /// Compute an anchor date aligned to the interval boundary.
    static func anchorDate(for interval: AggregationInterval, relativeTo date: Date) -> Date {
        let calendar = Calendar.current
        switch interval {
        case .hourly, .daily:
            return calendar.startOfDay(for: date)
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        case .yearly:
            let components = calendar.dateComponents([.year], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        }
    }
}
