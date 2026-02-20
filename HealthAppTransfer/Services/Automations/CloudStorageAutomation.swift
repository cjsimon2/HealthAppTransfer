import Foundation

// MARK: - Cloud Storage Parameters

/// Sendable snapshot of AutomationConfiguration fields needed for iCloud Drive export.
struct CloudStorageParameters: Sendable {
    let name: String
    let exportFormat: String
    let incrementalOnly: Bool
    let lastTriggeredAt: Date?
    let enabledTypeRawValues: [String]

    init(configuration: AutomationConfiguration) {
        self.name = configuration.name
        self.exportFormat = configuration.exportFormat
        self.incrementalOnly = configuration.incrementalOnly
        self.lastTriggeredAt = configuration.lastTriggeredAt
        self.enabledTypeRawValues = configuration.enabledTypeRawValues
    }
}

// MARK: - Cloud Storage Automation

/// Exports health data files to the app's iCloud Drive ubiquity container.
/// Files are organized by date and export format under `HealthExports/YYYY-MM-DD/`.
actor CloudStorageAutomation {

    // MARK: - Dependencies

    private let healthKitService: HealthKitService
    private let fileManager: FileManager

    init(healthKitService: HealthKitService, fileManager: FileManager = .default) {
        self.healthKitService = healthKitService
        self.fileManager = fileManager
    }

    // MARK: - Execute

    /// Export health data to iCloud Drive. Returns the URL of the written file.
    @discardableResult
    func execute(params: CloudStorageParameters) async throws -> URL {
        // Get the ubiquity container
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            throw CloudStorageError.iCloudUnavailable
        }

        // Fetch health data
        let samples = try await fetchSamples(params: params)

        guard !samples.isEmpty else {
            Loggers.automation.info("Cloud storage '\(params.name)': no samples to export")
            throw CloudStorageError.noData
        }

        // Format payload
        let (data, fileExtension) = try formatPayload(samples: samples, format: params.exportFormat)

        // Build destination path: Documents/HealthExports/YYYY-MM-DD/export_HHmmss.{ext}
        let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let exportDir = documentsURL
            .appendingPathComponent("HealthExports", isDirectory: true)
            .appendingPathComponent(dateString, isDirectory: true)

        try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)

        // Filename with timestamp
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmmss"
        let timeString = timeFormatter.string(from: Date())
        let fileName = "export_\(timeString).\(fileExtension)"
        let fileURL = exportDir.appendingPathComponent(fileName)

        // Write file
        try data.write(to: fileURL, options: .atomic)

        Loggers.automation.info("Cloud storage '\(params.name)': exported \(samples.count) samples to \(fileURL.lastPathComponent)")
        return fileURL
    }

    // MARK: - Fetch Samples

    private func fetchSamples(params: CloudStorageParameters) async throws -> [HealthSampleDTO] {
        let types = params.enabledTypeRawValues.compactMap { HealthDataType(rawValue: $0) }

        guard !types.isEmpty else {
            throw CloudStorageError.noTypesConfigured
        }

        let startDate: Date? = params.incrementalOnly ? params.lastTriggeredAt : nil

        var allSamples: [HealthSampleDTO] = []
        for type in types {
            guard type.isSampleBased else { continue }
            let samples = try await healthKitService.fetchSampleDTOs(
                for: type,
                from: startDate
            )
            allSamples.append(contentsOf: samples)
        }

        return allSamples
    }

    // MARK: - Format Payload

    private func formatPayload(samples: [HealthSampleDTO], format: String) throws -> (Data, String) {
        let formatter: any ExportFormatter
        let fileExtension: String

        switch format {
        case "json_v1":
            formatter = JSONv1Formatter()
            fileExtension = "json"
        case "json_v2":
            formatter = JSONv2Formatter()
            fileExtension = "json"
        case "csv":
            formatter = CSVFormatter()
            fileExtension = "csv"
        default:
            formatter = JSONv2Formatter()
            fileExtension = "json"
        }

        let options = ExportOptions(prettyPrint: true)
        let data = try formatter.format(samples: samples, options: options)
        return (data, fileExtension)
    }
}

// MARK: - Errors

enum CloudStorageError: LocalizedError {
    case iCloudUnavailable
    case noTypesConfigured
    case noData

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloud Drive is not available. Please sign in to iCloud in Settings."
        case .noTypesConfigured:
            return "No health data types configured."
        case .noData:
            return "No health data to export."
        }
    }
}
