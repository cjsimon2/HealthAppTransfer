import Foundation

// MARK: - Import Parser Service

/// Parses exported health data files (JSON v1, JSON v2, CSV) back into HealthSampleDTOs.
actor ImportParserService {

    // MARK: - Parse File

    /// Auto-detect format from file extension and parse into DTOs.
    func parseFile(at url: URL) async throws -> [HealthSampleDTO] {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "json":
            return try parseJSON(at: url)
        case "csv":
            return try parseCSV(at: url)
        default:
            throw ImportError.unsupportedFormat(ext)
        }
    }

    // MARK: - JSON Parsing

    private func parseJSON(at url: URL) throws -> [HealthSampleDTO] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try v1 (flat array) first
        if let samples = try? decoder.decode([HealthSampleDTO].self, from: data) {
            return samples
        }

        // Try v2 (grouped envelope)
        if let envelope = try? decoder.decode(V2ImportEnvelope.self, from: data) {
            return envelope.data.values.flatMap { $0 }
        }

        throw ImportError.invalidJSON
    }

    // MARK: - CSV Parsing

    private func parseCSV(at url: URL) throws -> [HealthSampleDTO] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard lines.count >= 2 else {
            throw ImportError.emptyFile
        }

        let header = parseCSVRow(lines[0])
        let expectedColumns = [
            "id", "type", "startDate", "endDate", "sourceName", "sourceBundleIdentifier",
            "value", "unit", "categoryValue", "workoutActivityType", "workoutDuration",
            "workoutTotalEnergyBurned", "workoutTotalDistance", "correlationValues",
            "characteristicValue", "metadata"
        ]

        guard header == expectedColumns else {
            throw ImportError.invalidCSVHeader
        }

        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var samples: [HealthSampleDTO] = []

        for lineIndex in 1..<lines.count {
            let fields = parseCSVRow(lines[lineIndex])
            guard fields.count == expectedColumns.count else { continue }

            guard let id = UUID(uuidString: fields[0]),
                  let type = HealthDataType(rawValue: fields[1]),
                  let startDate = iso8601.date(from: fields[2]),
                  let endDate = iso8601.date(from: fields[3]) else {
                continue
            }

            let correlationValues = parseCorrelationValues(fields[13])

            let dto = HealthSampleDTO(
                id: id,
                type: type,
                startDate: startDate,
                endDate: endDate,
                sourceName: fields[4],
                sourceBundleIdentifier: fields[5].isEmpty ? nil : fields[5],
                value: Double(fields[6]),
                unit: fields[7].isEmpty ? nil : fields[7],
                categoryValue: Int(fields[8]),
                workoutActivityType: UInt(fields[9]),
                workoutDuration: Double(fields[10]),
                workoutTotalEnergyBurned: Double(fields[11]),
                workoutTotalDistance: Double(fields[12]),
                correlationValues: correlationValues,
                characteristicValue: fields[14].isEmpty ? nil : fields[14],
                metadataJSON: fields[15].isEmpty ? nil : fields[15]
            )
            samples.append(dto)
        }

        guard !samples.isEmpty else {
            throw ImportError.noValidSamples
        }

        return samples
    }

    // MARK: - CSV Helpers

    /// Parse a single CSV row respecting RFC 4180 quoting.
    private func parseCSVRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var chars = line.makeIterator()

        while let char = chars.next() {
            if inQuotes {
                if char == "\"" {
                    // Check for escaped quote ("")
                    if let next = chars.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else if next == "," {
                            fields.append(current)
                            current = ""
                            inQuotes = false
                        } else {
                            current.append(next)
                            inQuotes = false
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
        }
        fields.append(current)
        return fields
    }

    /// Parse correlation values from "key1=value1;key2=value2" format.
    private func parseCorrelationValues(_ field: String) -> [String: Double]? {
        guard !field.isEmpty else { return nil }
        var result: [String: Double] = [:]
        for pair in field.split(separator: ";") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2, let value = Double(parts[1]) else { continue }
            result[String(parts[0])] = value
        }
        return result.isEmpty ? nil : result
    }
}

// MARK: - V2 Import Types

/// Decodable envelope for JSON v2 format import.
private struct V2ImportEnvelope: Decodable {
    let data: [String: [HealthSampleDTO]]
}

// MARK: - Import Errors

enum ImportError: LocalizedError {
    case unsupportedFormat(String)
    case invalidJSON
    case invalidCSVHeader
    case emptyFile
    case noValidSamples

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Unsupported file format: .\(ext). Use .json or .csv files."
        case .invalidJSON:
            return "Could not parse JSON file. Expected a flat array or grouped export format."
        case .invalidCSVHeader:
            return "CSV header does not match the expected export format."
        case .emptyFile:
            return "The file is empty or contains no data rows."
        case .noValidSamples:
            return "No valid health samples could be parsed from the file."
        }
    }
}
