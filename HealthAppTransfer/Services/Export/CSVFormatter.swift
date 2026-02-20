import Foundation

// MARK: - CSV Formatter

/// Exports health samples as CSV with one row per sample, header row, and proper escaping.
///
/// Output columns: id, type, startDate, endDate, sourceName, sourceBundleIdentifier,
/// value, unit, categoryValue, workoutActivityType, workoutDuration,
/// workoutTotalEnergyBurned, workoutTotalDistance, correlationValues, characteristicValue, metadata
struct CSVFormatter: ExportFormatter, Sendable {

    let formatIdentifier = "csv"

    private static let columns = [
        "id", "type", "startDate", "endDate", "sourceName", "sourceBundleIdentifier",
        "value", "unit", "categoryValue", "workoutActivityType", "workoutDuration",
        "workoutTotalEnergyBurned", "workoutTotalDistance", "correlationValues",
        "characteristicValue", "metadata"
    ]

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func format(samples: [HealthSampleDTO], options: ExportOptions) throws -> Data {
        var lines: [String] = []

        // Header row
        lines.append(Self.columns.joined(separator: ","))

        // Data rows
        for sample in samples {
            lines.append(rowString(for: sample))
        }

        let csvString = lines.joined(separator: "\n") + "\n"
        guard let data = csvString.data(using: .utf8) else {
            throw CSVFormatterError.encodingFailed
        }
        return data
    }

    // MARK: - Private Helpers

    private func rowString(for sample: HealthSampleDTO) -> String {
        var fields: [String] = []
        fields.append(escapeCSV(sample.id.uuidString))
        fields.append(escapeCSV(sample.type.rawValue))
        fields.append(escapeCSV(Self.iso8601.string(from: sample.startDate)))
        fields.append(escapeCSV(Self.iso8601.string(from: sample.endDate)))
        fields.append(escapeCSV(sample.sourceName))
        fields.append(escapeCSV(sample.sourceBundleIdentifier ?? ""))
        fields.append(sample.value.map { String($0) } ?? "")
        fields.append(escapeCSV(sample.unit ?? ""))
        fields.append(sample.categoryValue.map { String($0) } ?? "")
        fields.append(sample.workoutActivityType.map { String($0) } ?? "")
        fields.append(sample.workoutDuration.map { String($0) } ?? "")
        fields.append(sample.workoutTotalEnergyBurned.map { String($0) } ?? "")
        fields.append(sample.workoutTotalDistance.map { String($0) } ?? "")
        fields.append(formatCorrelationValues(sample.correlationValues))
        fields.append(escapeCSV(sample.characteristicValue ?? ""))
        fields.append(escapeCSV(sample.metadataJSON ?? ""))
        return fields.joined(separator: ",")
    }

    /// Escapes a CSV field per RFC 4180: wraps in double quotes if the value contains
    /// commas, double quotes, or newlines. Internal double quotes are doubled.
    private func escapeCSV(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") else {
            return value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func formatCorrelationValues(_ values: [String: Double]?) -> String {
        guard let values, !values.isEmpty else { return "" }
        // Deterministic key order for consistent output
        let pairs = values.keys.sorted().map { "\($0)=\(values[$0]!)" }
        return escapeCSV(pairs.joined(separator: ";"))
    }
}

// MARK: - Errors

enum CSVFormatterError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode CSV as UTF-8"
        }
    }
}
