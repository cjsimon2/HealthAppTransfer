import AppIntents
import Foundation

// MARK: - Export Health Data Intent

/// Exports health data to a file in the chosen format.
/// Available in Shortcuts app, Siri, and Action button.
struct ExportHealthDataIntent: AppIntent {

    static var title: LocalizedStringResource = "Export Health Data"
    static var description = IntentDescription(
        "Export selected health data types to a file.",
        categoryName: "Health Data"
    )
    static var openAppWhenRun = false

    // MARK: - Parameters

    @Parameter(title: "Format", default: .csv)
    var format: ExportFormatAppEnum

    @Parameter(title: "Health Types")
    var types: [HealthTypeAppEntity]

    @Parameter(title: "Date Range", default: .lastMonth)
    var dateRange: DateRangeAppEnum

    // MARK: - Parameter Summary

    static var parameterSummary: some ParameterSummary {
        Summary("Export \(\.$types) as \(\.$format) for \(\.$dateRange)")
    }

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let healthKitService = HealthKitService()
        try await healthKitService.requestAuthorization()

        let exportService = ExportService(healthKitService: healthKitService)

        let healthTypes = types.compactMap(\.healthDataType)
        guard !healthTypes.isEmpty else {
            throw IntentError.noTypesSelected
        }

        let result = try await exportService.export(
            types: healthTypes,
            format: format.exportFormat,
            startDate: dateRange.startDate,
            endDate: Date()
        )

        let data = try Data(contentsOf: result.fileURL)
        let file = IntentFile(
            data: data,
            filename: result.fileURL.lastPathComponent,
            type: .data
        )

        return .result(value: file)
    }
}

// MARK: - Intent Errors

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case noTypesSelected
    case noDataFound
    case syncFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noTypesSelected:
            return "No health data types selected."
        case .noDataFound:
            return "No data found for the selected types and date range."
        case .syncFailed:
            return "Sync failed. Please try again."
        }
    }
}
