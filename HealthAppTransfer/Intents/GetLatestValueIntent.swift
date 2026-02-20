import AppIntents
import Foundation
import HealthKit

// MARK: - Get Latest Value Intent

/// Returns the latest value for a given health data type as formatted text.
/// Available in Shortcuts app, Siri, and Action button.
struct GetLatestValueIntent: AppIntent {

    static var title: LocalizedStringResource = "Get Latest Health Value"
    static var description = IntentDescription(
        "Get the most recent value for a health data type.",
        categoryName: "Health Data"
    )
    static var openAppWhenRun = false

    // MARK: - Parameters

    @Parameter(title: "Health Type")
    var type: HealthTypeAppEntity

    // MARK: - Parameter Summary

    static var parameterSummary: some ParameterSummary {
        Summary("Get latest value for \(\.$type)")
    }

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let healthType = type.healthDataType else {
            throw IntentError.noTypesSelected
        }

        let healthKitService = HealthKitService()
        try await healthKitService.requestAuthorization()

        // Characteristic types use a different read path
        if healthType.kind == .characteristic {
            let store = HKHealthStore()
            guard let value = HealthSampleMapper.readCharacteristic(healthType, from: store) else {
                throw IntentError.noDataFound
            }
            return .result(value: "\(healthType.displayName): \(value)")
        }

        // Fetch the single most recent sample
        let samples = try await healthKitService.fetchSampleDTOs(
            for: healthType,
            limit: 1
        )

        guard let latest = samples.first else {
            throw IntentError.noDataFound
        }

        let formatted = formatSample(latest, type: healthType)
        return .result(value: formatted)
    }

    // MARK: - Formatting

    private func formatSample(_ sample: HealthSampleDTO, type: HealthDataType) -> String {
        let name = type.displayName

        // Quantity types
        if let value = sample.value, let unit = sample.unit {
            let formatted = formatNumber(value)
            return "\(name): \(formatted) \(unit)"
        }

        // Correlation types (e.g. blood pressure)
        if let correlationValues = sample.correlationValues {
            let parts = correlationValues
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \(formatNumber($0.value))" }
            let unit = sample.unit ?? ""
            return "\(name): \(parts.joined(separator: ", ")) \(unit)".trimmingCharacters(in: .whitespaces)
        }

        // Workout types
        if let duration = sample.workoutDuration {
            let minutes = Int(duration / 60)
            var result = "\(name): \(minutes) min"
            if let energy = sample.workoutTotalEnergyBurned {
                result += ", \(formatNumber(energy)) kcal"
            }
            return result
        }

        // Category types
        if sample.categoryValue != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            return "\(name): recorded \(dateFormatter.string(from: sample.startDate))"
        }

        return "\(name): No value available"
    }

    private func formatNumber(_ value: Double) -> String {
        if value == value.rounded() && value < 100_000 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
