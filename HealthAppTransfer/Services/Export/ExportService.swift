import CoreLocation
import Foundation
import HealthKit
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

        // GPX export uses a separate pipeline that fetches workout routes
        if format == .gpx {
            return try await exportGPX(
                startDate: startDate,
                endDate: endDate,
                progressHandler: progressHandler
            )
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
        let device = await deviceInfo()
        let options = ExportOptions(
            startDate: startDate,
            endDate: endDate,
            prettyPrint: true,
            deviceName: device.name,
            deviceModel: device.model,
            systemVersion: device.systemVersion,
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

    // MARK: - Export from Pre-fetched Samples (macOS)

    /// Export pre-fetched samples (bypasses HealthKit). Used on macOS where data comes from SwiftData.
    func exportFromSamples(
        samples: [HealthSampleDTO],
        format: ExportFormat,
        types: [HealthDataType]
    ) async throws -> ExportResult {
        guard !samples.isEmpty else {
            throw ExportError.noDataFound
        }

        if format == .gpx {
            // GPX requires HealthKit workout route data which isn't available from pre-fetched samples
            throw ExportError.gpxRequiresWorkouts
        }

        Loggers.export.info("Starting \(format.rawValue) export from \(samples.count) pre-fetched samples")

        let device = await deviceInfo()
        let options = ExportOptions(
            prettyPrint: true,
            deviceName: device.name,
            deviceModel: device.model,
            systemVersion: device.systemVersion,
            appVersion: appVersion()
        )

        let formatter = makeFormatter(for: format)
        let data = try formatter.format(samples: samples, options: options)
        let fileURL = try writeToTempFile(data: data, format: format, types: types)
        let fileSize = Int64(data.count)

        Loggers.export.info("Export complete: \(samples.count) samples, \(fileSize) bytes")

        return ExportResult(
            fileURL: fileURL,
            format: format,
            sampleCount: samples.count,
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
        case .gpx: return JSONv2Formatter() // GPX uses exportGPX() directly; this path is unreachable
        }
    }

    // MARK: - GPX Export

    /// Fetches workout routes from HealthKit and formats them as GPX XML.
    private func exportGPX(
        startDate: Date?,
        endDate: Date?,
        progressHandler: (@Sendable (ExportProgress) -> Void)?
    ) async throws -> ExportResult {
        Loggers.export.info("Starting GPX export")

        progressHandler?(ExportProgress(completedTypes: 0, totalTypes: 2, currentTypeName: "Workouts"))

        // Fetch workouts
        let workouts = try await healthKitService.fetchSamples(
            for: .workout,
            from: startDate,
            to: endDate
        ).compactMap { $0 as? HKWorkout }

        guard !workouts.isEmpty else {
            throw ExportError.noDataFound
        }

        progressHandler?(ExportProgress(completedTypes: 1, totalTypes: 2, currentTypeName: "Routes"))

        // Build GPX tracks from workouts with routes
        var tracks: [GPXTrack] = []

        for workout in workouts {
            let routes = try await healthKitService.fetchWorkoutRoutes(for: workout)
            guard !routes.isEmpty else { continue }

            // Fetch heart rate samples for this workout's time window
            let hrSamples: [HKQuantitySample]
            do {
                hrSamples = try await healthKitService.fetchHeartRateSamples(
                    from: workout.startDate,
                    to: workout.endDate
                )
            } catch {
                Loggers.export.warning("Failed to fetch heart rate for workout: \(error.localizedDescription)")
                hrSamples = []
            }

            let bpmUnit = HKUnit.count().unitDivided(by: .minute())

            for route in routes {
                let locations = try await healthKitService.fetchRouteLocations(from: route)
                guard !locations.isEmpty else { continue }

                let points = locations.map { location in
                    let hr = Self.nearestHeartRate(
                        for: location.timestamp,
                        in: hrSamples,
                        unit: bpmUnit
                    )
                    return GPXRoutePoint(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        elevation: location.verticalAccuracy >= 0 ? location.altitude : nil,
                        timestamp: location.timestamp,
                        heartRate: hr
                    )
                }

                let trackName = workoutActivityName(workout.workoutActivityType)
                tracks.append(GPXTrack(name: trackName, startDate: workout.startDate, points: points))
            }
        }

        guard !tracks.isEmpty else {
            throw ExportError.noDataFound
        }

        progressHandler?(ExportProgress(completedTypes: 2, totalTypes: 2, currentTypeName: nil))

        let formatter = GPXFormatter()
        let data = try formatter.format(tracks: tracks)
        let fileURL = try writeToTempFile(data: data, format: .gpx, types: [.workout])

        let totalPoints = tracks.reduce(0) { $0 + $1.points.count }
        Loggers.export.info("GPX export complete: \(tracks.count) tracks, \(totalPoints) points")

        return ExportResult(
            fileURL: fileURL,
            format: .gpx,
            sampleCount: totalPoints,
            fileSizeBytes: Int64(data.count),
            exportedTypes: [.workout]
        )
    }

    /// Finds the nearest heart rate sample within 5 seconds of a given timestamp.
    /// HR samples are expected to be sorted ascending by startDate.
    static func nearestHeartRate(
        for timestamp: Date,
        in samples: [HKQuantitySample],
        unit: HKUnit,
        maxInterval: TimeInterval = 5.0
    ) -> Double? {
        guard !samples.isEmpty else { return nil }

        var bestSample: HKQuantitySample?
        var bestDistance: TimeInterval = .greatestFiniteMagnitude

        for sample in samples {
            let distance = abs(sample.startDate.timeIntervalSince(timestamp))
            if distance < bestDistance {
                bestDistance = distance
                bestSample = sample
            }
            // Samples are sorted ascending — once we pass the timestamp and distance
            // starts growing, no future sample will be closer
            if sample.startDate > timestamp && distance > bestDistance {
                break
            }
        }

        guard let best = bestSample, bestDistance <= maxInterval else { return nil }
        return best.quantity.doubleValue(for: unit)
    }

    /// Maps HKWorkoutActivityType to a human-readable name for GPX track names.
    private func workoutActivityName(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .hiking: return "Hiking"
        case .swimming: return "Swimming"
        case .crossCountrySkiing: return "Cross Country Skiing"
        case .downhillSkiing: return "Downhill Skiing"
        case .snowboarding: return "Snowboarding"
        case .rowing: return "Rowing"
        case .paddleSports: return "Paddle Sports"
        case .surfingSports: return "Surfing"
        case .golf: return "Golf"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Strength Training"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stair Climbing"
        default: return "Workout"
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

    private func deviceInfo() async -> (name: String?, model: String?, systemVersion: String?) {
        #if canImport(UIKit)
        return await MainActor.run {
            (UIDevice.current.name, UIDevice.current.model, UIDevice.current.systemVersion)
        }
        #else
        return (Host.current().localizedName, "Mac", ProcessInfo.processInfo.operatingSystemVersionString)
        #endif
    }

    private func appVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

#if canImport(UIKit)
import UIKit
#endif
