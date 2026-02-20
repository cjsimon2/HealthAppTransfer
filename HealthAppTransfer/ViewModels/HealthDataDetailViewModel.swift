import Foundation

// MARK: - Health Data Detail ViewModel

@MainActor
class HealthDataDetailViewModel: ObservableObject {

    // MARK: - Published State

    @Published var samples: [AggregatedSample] = []
    @Published var recentDTOs: [HealthSampleDTO] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Properties

    let dataType: HealthDataType
    private let healthKitService: HealthKitService
    let aggregationEngine: AggregationEngine

    // MARK: - Init

    init(dataType: HealthDataType, healthKitService: HealthKitService) {
        self.dataType = dataType
        self.healthKitService = healthKitService
        self.aggregationEngine = AggregationEngine()
    }

    // MARK: - Computed Properties

    var latestValue: String {
        guard let last = samples.last(where: { $0.count > 0 }) else { return "—" }
        let value = last.sum ?? last.average ?? last.latest ?? 0
        return formatValue(value, unit: last.unit)
    }

    var minValue: String {
        let values = samples.compactMap(\.min)
        guard let min = values.min() else { return "—" }
        return formatValue(min, unit: samples.first?.unit ?? "")
    }

    var maxValue: String {
        let values = samples.compactMap(\.max)
        guard let max = values.max() else { return "—" }
        return formatValue(max, unit: samples.first?.unit ?? "")
    }

    var avgValue: String {
        let values = samples.compactMap(\.average)
        guard !values.isEmpty else { return "—" }
        let avg = values.reduce(0, +) / Double(values.count)
        return formatValue(avg, unit: samples.first?.unit ?? "")
    }

    var displayUnit: String {
        samples.first?.unit ?? ""
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        await loadAggregatedData()
        await loadRecentSamples()
    }

    private func loadAggregatedData() async {
        guard dataType.isQuantityType else { return }

        let range = ChartDateRange.week.defaultDateRange
        do {
            samples = try await aggregationEngine.aggregate(
                type: dataType,
                operations: [.sum, .average, .min, .max],
                interval: .daily,
                from: range.start,
                to: range.end
            )
            error = nil
        } catch {
            self.error = error
            samples = []
        }
    }

    private func loadRecentSamples() async {
        guard dataType.isSampleBased else { return }

        do {
            recentDTOs = try await healthKitService.fetchSampleDTOs(
                for: dataType,
                limit: 20
            )
        } catch {
            // Non-critical — stats + chart still display
        }
    }

    // MARK: - Export

    func exportJSON() -> Data? {
        guard !recentDTOs.isEmpty else { return nil }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(recentDTOs)
    }

    // MARK: - Helpers

    private func formatValue(_ value: Double, unit: String) -> String {
        if value == value.rounded() {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }
}
