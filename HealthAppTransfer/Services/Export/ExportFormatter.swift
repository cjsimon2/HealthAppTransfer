import Foundation

// MARK: - Export Formatter Protocol

/// Formats health samples into exportable data (JSON, CSV, etc.).
protocol ExportFormatter: Sendable {

    /// The format identifier used in ExportRecord (e.g. "json_v1", "json_v2").
    var formatIdentifier: String { get }

    /// Encode an array of health samples into the target format.
    /// Samples may span multiple HealthDataType values — the formatter decides grouping.
    func format(samples: [HealthSampleDTO], options: ExportOptions) throws -> Data
}

// MARK: - Export Options

/// Configuration for an export operation.
struct ExportOptions: Sendable {

    /// Start of the exported date range (nil = unbounded).
    let startDate: Date?

    /// End of the exported date range (nil = unbounded).
    let endDate: Date?

    /// Emit indented JSON for readability.
    let prettyPrint: Bool

    /// Device name to embed in metadata (v2 only).
    let deviceName: String?

    /// Device model to embed in metadata (v2 only).
    let deviceModel: String?

    /// OS version to embed in metadata (v2 only).
    let systemVersion: String?

    /// App version string to embed in metadata (v2 only).
    let appVersion: String?

    init(
        startDate: Date? = nil,
        endDate: Date? = nil,
        prettyPrint: Bool = false,
        deviceName: String? = nil,
        deviceModel: String? = nil,
        systemVersion: String? = nil,
        appVersion: String? = nil
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.prettyPrint = prettyPrint
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.systemVersion = systemVersion
        self.appVersion = appVersion
    }
}

// MARK: - Shared Encoder

extension ExportFormatter {

    /// Returns a JSONEncoder configured with ISO 8601 dates and optional pretty printing.
    func makeEncoder(prettyPrint: Bool) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.sortedKeys]
        }
        return encoder
    }
}
