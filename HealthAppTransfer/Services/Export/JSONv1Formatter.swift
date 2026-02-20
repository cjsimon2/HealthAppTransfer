import Foundation

// MARK: - JSON v1 Formatter

/// Exports health samples as a flat JSON array matching the Health Auto Export v6 schema.
///
/// Output structure:
/// ```json
/// [
///   { "id": "...", "type": "stepCount", "startDate": "...", ... },
///   { "id": "...", "type": "heartRate", "startDate": "...", ... }
/// ]
/// ```
struct JSONv1Formatter: ExportFormatter, Sendable {

    let formatIdentifier = "json_v1"

    func format(samples: [HealthSampleDTO], options: ExportOptions) throws -> Data {
        let encoder = makeEncoder(prettyPrint: options.prettyPrint)
        return try encoder.encode(samples)
    }
}
