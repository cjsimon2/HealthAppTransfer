import Foundation
import SwiftData

// MARK: - Correlation Record

/// Persisted result of a correlation analysis between two health metrics.
/// Enables tracking how correlations change over time.
@Model
final class CorrelationRecord {

    /// Raw value of the first HealthDataType.
    var typeARaw: String

    /// Raw value of the second HealthDataType.
    var typeBRaw: String

    /// Pearson correlation coefficient (-1.0 to 1.0).
    var rValue: Double

    /// Number of data points in the correlation.
    var pointCount: Int

    /// When the correlation was computed.
    var date: Date

    /// Human-readable strength label ("Weak", "Moderate", "Strong").
    var strengthLabel: String

    init(typeARaw: String, typeBRaw: String, rValue: Double, pointCount: Int, date: Date, strengthLabel: String) {
        self.typeARaw = typeARaw
        self.typeBRaw = typeBRaw
        self.rValue = rValue
        self.pointCount = pointCount
        self.date = date
        self.strengthLabel = strengthLabel
    }
}
