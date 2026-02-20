import Foundation

// MARK: - JSON v2 Formatter

/// Exports health samples grouped by type with a metadata header.
///
/// Output structure:
/// ```json
/// {
///   "metadata": {
///     "formatVersion": "2.0",
///     "exportDate": "2024-06-15T10:30:00Z",
///     "dateRange": { "start": "...", "end": "..." },
///     "device": { "name": "iPhone", "model": "iPhone15,2", "systemVersion": "17.5" },
///     "appVersion": "1.0.0",
///     "sampleCount": 1234,
///     "types": ["stepCount", "heartRate"]
///   },
///   "data": {
///     "stepCount": [ ... ],
///     "heartRate": [ ... ]
///   }
/// }
/// ```
struct JSONv2Formatter: ExportFormatter, Sendable {

    let formatIdentifier = "json_v2"

    func format(samples: [HealthSampleDTO], options: ExportOptions) throws -> Data {
        // Group samples by type
        var grouped: [String: [HealthSampleDTO]] = [:]
        for sample in samples {
            grouped[sample.type.rawValue, default: []].append(sample)
        }

        // Sort type keys for deterministic output
        let sortedTypes = grouped.keys.sorted()

        let metadata = V2Metadata(
            formatVersion: "2.0",
            exportDate: Date(),
            dateRange: makeDateRange(samples: samples, options: options),
            device: makeDeviceInfo(options: options),
            appVersion: options.appVersion,
            sampleCount: samples.count,
            types: sortedTypes
        )

        let envelope = V2Envelope(
            metadata: metadata,
            data: grouped
        )

        let encoder = makeEncoder(prettyPrint: options.prettyPrint)
        return try encoder.encode(envelope)
    }

    // MARK: - Private Helpers

    private func makeDateRange(samples: [HealthSampleDTO], options: ExportOptions) -> V2DateRange? {
        let start = options.startDate ?? samples.map(\.startDate).min()
        let end = options.endDate ?? samples.map(\.endDate).max()
        guard let start, let end else { return nil }
        return V2DateRange(start: start, end: end)
    }

    private func makeDeviceInfo(options: ExportOptions) -> V2DeviceInfo? {
        guard options.deviceName != nil || options.deviceModel != nil || options.systemVersion != nil else {
            return nil
        }
        return V2DeviceInfo(
            name: options.deviceName,
            model: options.deviceModel,
            systemVersion: options.systemVersion
        )
    }
}

// MARK: - V2 Codable Types

private struct V2Envelope: Encodable {
    let metadata: V2Metadata
    let data: [String: [HealthSampleDTO]]
}

private struct V2Metadata: Encodable {
    let formatVersion: String
    let exportDate: Date
    let dateRange: V2DateRange?
    let device: V2DeviceInfo?
    let appVersion: String?
    let sampleCount: Int
    let types: [String]
}

private struct V2DateRange: Encodable {
    let start: Date
    let end: Date
}

private struct V2DeviceInfo: Encodable {
    let name: String?
    let model: String?
    let systemVersion: String?
}
