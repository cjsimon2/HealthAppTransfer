import Foundation
import SwiftData

// MARK: - Export Record

/// Tracks completed health data exports for history and deduplication.
@Model
final class ExportRecord {

    // MARK: - Properties

    /// Export format: "json_v1", "json_v2", "csv", "gpx".
    var format: String

    /// Destination: "file", "rest_api", "mqtt", "cloud_storage", "home_assistant".
    var destination: String

    /// Number of samples included in this export.
    var sampleCount: Int = 0

    /// HealthKit types included (stored as raw strings).
    var exportedTypeRawValues: [String] = []

    /// Date range start of exported data.
    var dataStartDate: Date?

    /// Date range end of exported data.
    var dataEndDate: Date?

    /// Whether the export completed successfully.
    var succeeded: Bool = true

    /// Error message if the export failed.
    var errorMessage: String?

    /// File size in bytes (for file exports).
    var fileSizeBytes: Int64?

    /// When the export was initiated.
    var exportedAt: Date = Date()

    // MARK: - Init

    init(
        format: String,
        destination: String,
        sampleCount: Int = 0,
        exportedTypeRawValues: [String] = [],
        succeeded: Bool = true
    ) {
        self.format = format
        self.destination = destination
        self.sampleCount = sampleCount
        self.exportedTypeRawValues = exportedTypeRawValues
        self.succeeded = succeeded
        self.exportedAt = Date()
    }
}
