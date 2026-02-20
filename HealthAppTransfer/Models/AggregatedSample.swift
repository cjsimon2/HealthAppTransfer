import Foundation

// MARK: - Aggregation Interval

/// Time interval for grouping health data aggregations.
enum AggregationInterval: String, Codable, Sendable, CaseIterable {
    case hourly
    case daily
    case weekly
    case monthly
    case yearly

    var dateComponents: DateComponents {
        switch self {
        case .hourly: return DateComponents(hour: 1)
        case .daily: return DateComponents(day: 1)
        case .weekly: return DateComponents(day: 7)
        case .monthly: return DateComponents(month: 1)
        case .yearly: return DateComponents(year: 1)
        }
    }
}

// MARK: - Aggregation Operation

/// Statistical operation to apply during aggregation.
enum AggregationOperation: String, Codable, Sendable, CaseIterable {
    case sum
    case average
    case min
    case max
    case count
    case latest
}

// MARK: - Aggregated Sample

/// A single aggregated data point for a time interval.
struct AggregatedSample: Codable, Sendable {
    let startDate: Date
    let endDate: Date
    let sum: Double?
    let average: Double?
    let min: Double?
    let max: Double?
    let latest: Double?
    /// 1 if data exists in the interval, 0 otherwise.
    let count: Int
    let unit: String
}

// MARK: - Aggregation Error

enum AggregationError: Error, LocalizedError {
    case unsupportedType(HealthDataType)

    var errorDescription: String? {
        switch self {
        case .unsupportedType(let type):
            return "Aggregation only supports quantity types, not \(type.displayName)"
        }
    }
}
