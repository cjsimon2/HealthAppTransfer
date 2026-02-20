import AppIntents
import Foundation

// MARK: - Health Type App Entity

/// AppEntity representing a health data type for Shortcuts integration.
struct HealthTypeAppEntity: AppEntity {

    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Health Data Type",
        numericFormat: "\(placeholder: .int) health data types"
    )

    static var defaultQuery = HealthTypeEntityQuery()

    var id: String
    var displayName: String
    var category: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)", subtitle: "\(category)")
    }

    init(from type: HealthDataType) {
        self.id = type.rawValue
        self.displayName = type.displayName
        self.category = type.category.displayName
    }

    /// Convert back to HealthDataType.
    var healthDataType: HealthDataType? {
        HealthDataType(rawValue: id)
    }
}

// MARK: - Entity Query

struct HealthTypeEntityQuery: EntityStringQuery {

    func entities(for identifiers: [String]) async throws -> [HealthTypeAppEntity] {
        identifiers.compactMap { id in
            guard let type = HealthDataType(rawValue: id) else { return nil }
            return HealthTypeAppEntity(from: type)
        }
    }

    func entities(matching string: String) async throws -> [HealthTypeAppEntity] {
        let lowered = string.lowercased()
        return HealthDataType.allCases
            .filter { $0.displayName.lowercased().contains(lowered) }
            .map { HealthTypeAppEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [HealthTypeAppEntity] {
        // Surface the most commonly used types
        let commonTypes: [HealthDataType] = [
            .stepCount, .heartRate, .activeEnergyBurned, .bodyMass,
            .sleepAnalysis, .oxygenSaturation, .restingHeartRate,
            .distanceWalkingRunning, .vo2Max, .workout
        ]
        return commonTypes.map { HealthTypeAppEntity(from: $0) }
    }
}

// MARK: - Export Format App Enum

/// AppEnum wrapping ExportFormat for Shortcuts parameter selection.
enum ExportFormatAppEnum: String, AppEnum {
    case jsonFlat = "json_v1"
    case jsonGrouped = "json_v2"
    case csv = "csv"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Export Format")

    static var caseDisplayRepresentations: [ExportFormatAppEnum: DisplayRepresentation] = [
        .jsonFlat: "JSON (Flat)",
        .jsonGrouped: "JSON (Grouped)",
        .csv: "CSV",
    ]

    var exportFormat: ExportFormat {
        switch self {
        case .jsonFlat: return .jsonV1
        case .jsonGrouped: return .jsonV2
        case .csv: return .csv
        }
    }
}

// MARK: - Date Range App Enum

/// Predefined date ranges for Shortcuts convenience.
enum DateRangeAppEnum: String, AppEnum {
    case today
    case lastWeek
    case lastMonth
    case lastYear
    case allTime

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Date Range")

    static var caseDisplayRepresentations: [DateRangeAppEnum: DisplayRepresentation] = [
        .today: "Today",
        .lastWeek: "Last 7 Days",
        .lastMonth: "Last 30 Days",
        .lastYear: "Last Year",
        .allTime: "All Time",
    ]

    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .today: return calendar.startOfDay(for: now)
        case .lastWeek: return calendar.date(byAdding: .day, value: -7, to: now)
        case .lastMonth: return calendar.date(byAdding: .day, value: -30, to: now)
        case .lastYear: return calendar.date(byAdding: .year, value: -1, to: now)
        case .allTime: return nil
        }
    }
}
