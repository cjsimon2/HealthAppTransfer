import Foundation
import OSLog

// MARK: - Export Format

/// Supported export file formats.
enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case jsonV1 = "json_v1"
    case jsonV2 = "json_v2"
    case csv = "csv"
    case gpx = "gpx"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jsonV1: return "JSON (Flat)"
        case .jsonV2: return "JSON (Grouped)"
        case .csv: return "CSV"
        case .gpx: return "GPX"
        }
    }

    var fileExtension: String {
        switch self {
        case .jsonV1, .jsonV2: return "json"
        case .csv: return "csv"
        case .gpx: return "gpx"
        }
    }

    var mimeType: String {
        switch self {
        case .jsonV1, .jsonV2: return "application/json"
        case .csv: return "text/csv"
        case .gpx: return "application/gpx+xml"
        }
    }
}

// MARK: - Export Progress

/// Tracks progress of an export operation.
struct ExportProgress: Sendable {
    let completedTypes: Int
    let totalTypes: Int
    let currentTypeName: String?

    var fraction: Double {
        guard totalTypes > 0 else { return 0 }
        return Double(completedTypes) / Double(totalTypes)
    }
}

// MARK: - Export Result

/// Result of a completed export operation.
struct ExportResult: Sendable {
    let fileURL: URL
    let format: ExportFormat
    let sampleCount: Int
    let fileSizeBytes: Int64
    let exportedTypes: [HealthDataType]
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case noTypesSelected
    case noDataFound
    case gpxRequiresWorkouts
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noTypesSelected:
            return "No health data types selected for export"
        case .noDataFound:
            return "No data found for the selected types and date range"
        case .gpxRequiresWorkouts:
            return "GPX format requires workout data with route information"
        case .writeFailed(let error):
            return "Failed to write export file: \(error.localizedDescription)"
        }
    }
}

// MARK: - Export Service

/// Orchestrates the full export pipeline: fetch data, format, write to file.
actor ExportService {

    // MARK: - Properties

    private let healthKitService: HealthKitService
    private let aggregationEngine: AggregationEngine

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
        self.aggregationEngine = AggregationEngine()
    }

    // MARK: - Export

    /// Run a full export: fetch samples for each selected type, format, and write to a temp file.
    /// Returns the file URL for sharing via UIActivityViewController or NSSavePanel.
    func export(
        types: [HealthDataType],
        format: ExportFormat,
        startDate: Date?,
        endDate: Date?,
        aggregationEnabled: Bool = false,
        aggregationInterval: AggregationInterval = .daily,
        progressHandler: (@Sendable (ExportProgress) -> Void)? = nil
    ) async throws -> ExportResult {
        guard !types.isEmpty else {
            throw ExportError.noTypesSelected
        }

        if format == .gpx && !types.contains(.workout) {
            throw ExportError.gpxRequiresWorkouts
        }

        Loggers.export.info("Starting \(format.rawValue) export for \(types.count) types")

        // Fetch samples for each type
        var allSamples: [HealthSampleDTO] = []
        let sampleBasedTypes = types.filter(\.isSampleBased)

        for (index, type) in sampleBasedTypes.enumerated() {
            progressHandler?(ExportProgress(
                completedTypes: index,
                totalTypes: sampleBasedTypes.count,
                currentTypeName: type.displayName
            ))

            do {
                let dtos = try await healthKitService.fetchSampleDTOs(
                    for: type,
                    from: startDate,
                    to: endDate
                )
                allSamples.append(contentsOf: dtos)
            } catch {
                Loggers.export.warning("Failed to fetch \(type.rawValue): \(error.localizedDescription)")
                // Continue with other types
            }
        }

        progressHandler?(ExportProgress(
            completedTypes: sampleBasedTypes.count,
            totalTypes: sampleBasedTypes.count,
            currentTypeName: nil
        ))

        guard !allSamples.isEmpty else {
            throw ExportError.noDataFound
        }

        // Format the data
        let options = ExportOptions(
            startDate: startDate,
            endDate: endDate,
            prettyPrint: true,
            deviceName: deviceName(),
            deviceModel: deviceModel(),
            systemVersion: systemVersion(),
            appVersion: appVersion()
        )

        let formatter = makeFormatter(for: format)
        let data = try formatter.format(samples: allSamples, options: options)

        // Write to temp file
        let fileURL = try writeToTempFile(data: data, format: format, types: types)
        let fileSize = Int64(data.count)

        Loggers.export.info("Export complete: \(allSamples.count) samples, \(fileSize) bytes")

        return ExportResult(
            fileURL: fileURL,
            format: format,
            sampleCount: allSamples.count,
            fileSizeBytes: fileSize,
            exportedTypes: types
        )
    }

    // MARK: - Formatter Factory

    private func makeFormatter(for format: ExportFormat) -> any ExportFormatter {
        switch format {
        case .jsonV1: return JSONv1Formatter()
        case .jsonV2: return JSONv2Formatter()
        case .csv: return CSVFormatter()
        case .gpx: return JSONv1Formatter() // GPX uses separate path for route data
        }
    }

    // MARK: - File Writing

    private func writeToTempFile(data: Data, format: ExportFormat, types: [HealthDataType]) throws -> URL {
        let fileName = generateFileName(format: format, types: types)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw ExportError.writeFailed(error)
        }

        return fileURL
    }

    private func generateFileName(format: ExportFormat, types: [HealthDataType]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let typeSuffix: String
        if types.count == 1, let first = types.first {
            typeSuffix = first.rawValue
        } else {
            typeSuffix = "\(types.count)-types"
        }

        return "health-export_\(typeSuffix)_\(timestamp).\(format.fileExtension)"
    }

    // MARK: - Device Info

    private func deviceName() -> String? {
        #if canImport(UIKit)
        return UIDevice.current.name
        #else
        return Host.current().localizedName
        #endif
    }

    private func deviceModel() -> String? {
        #if canImport(UIKit)
        return UIDevice.current.model
        #else
        return "Mac"
        #endif
    }

    private func systemVersion() -> String? {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }

    private func appVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

#if canImport(UIKit)
import UIKit
#endif
