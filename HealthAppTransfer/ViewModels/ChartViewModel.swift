import Foundation

// MARK: - Chart Date Range

/// Predefined date ranges for chart display.
enum ChartDateRange: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .day: return String(localized: "chartRange.day", defaultValue: "D")
        case .week: return String(localized: "chartRange.week", defaultValue: "W")
        case .month: return String(localized: "chartRange.month", defaultValue: "M")
        case .year: return String(localized: "chartRange.year", defaultValue: "Y")
        case .custom: return String(localized: "chartRange.custom", defaultValue: "…")
        }
    }

    var interval: AggregationInterval {
        switch self {
        case .day: return .hourly
        case .week, .month, .custom: return .daily
        case .year: return .monthly
        }
    }

    var defaultDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = Date()
        switch self {
        case .day:
            return (calendar.startOfDay(for: end), end)
        case .week:
            return (calendar.date(byAdding: .day, value: -7, to: end) ?? end, end)
        case .month:
            return (calendar.date(byAdding: .month, value: -1, to: end) ?? end, end)
        case .year:
            return (calendar.date(byAdding: .year, value: -1, to: end) ?? end, end)
        case .custom:
            return (calendar.date(byAdding: .month, value: -1, to: end) ?? end, end)
        }
    }
}

// MARK: - Chart Mark Type

/// Visual mark type for chart rendering.
enum ChartMarkType: String, CaseIterable, Identifiable {
    case line
    case bar
    case area

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .line: return String(localized: "chartType.line", defaultValue: "Line")
        case .bar: return String(localized: "chartType.bar", defaultValue: "Bar")
        case .area: return String(localized: "chartType.area", defaultValue: "Area")
        }
    }

    var iconName: String {
        switch self {
        case .line: return "chart.xyaxis.line"
        case .bar: return "chart.bar.fill"
        case .area: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Chart ViewModel

@MainActor
class ChartViewModel: ObservableObject {

    // MARK: - Published State

    @Published var samples: [AggregatedSample] = []
    @Published var selectedRange: ChartDateRange = .week
    @Published var markType: ChartMarkType = .line
    @Published var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Published var customEndDate = Date()
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedSample: AggregatedSample?

    // MARK: - Properties

    let dataType: HealthDataType
    private let aggregationEngine: AggregationEngine

    // MARK: - Init

    init(dataType: HealthDataType, aggregationEngine: AggregationEngine) {
        self.dataType = dataType
        self.aggregationEngine = aggregationEngine
    }

    // MARK: - Computed Properties

    var displayUnit: String {
        samples.first?.unit ?? ""
    }

    var isEmpty: Bool {
        samples.allSatisfy { $0.count == 0 }
    }

    var activeSamples: [AggregatedSample] {
        samples.filter { $0.count > 0 }
    }

    var startDate: Date {
        if selectedRange == .custom { return customStartDate }
        return selectedRange.defaultDateRange.start
    }

    var endDate: Date {
        if selectedRange == .custom { return customEndDate }
        return selectedRange.defaultDateRange.end
    }

    var interval: AggregationInterval {
        guard selectedRange == .custom else { return selectedRange.interval }
        let days = Calendar.current.dateComponents([.day], from: customStartDate, to: customEndDate).day ?? 0
        if days <= 1 { return .hourly }
        if days <= 90 { return .daily }
        if days <= 365 { return .weekly }
        return .monthly
    }

    // MARK: - Data Loading

    func loadData() async {
        guard dataType.isQuantityType else {
            error = AggregationError.unsupportedType(dataType)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            samples = try await aggregationEngine.aggregate(
                type: dataType,
                operations: [.sum, .average, .min, .max],
                interval: interval,
                from: startDate,
                to: endDate
            )
            error = nil
        } catch {
            self.error = error
            samples = []
        }
    }

    // MARK: - Value Extraction

    /// Primary display value: sum for cumulative types, average for discrete.
    func chartValue(for sample: AggregatedSample) -> Double {
        sample.sum ?? sample.average ?? sample.latest ?? 0
    }

    /// Find the sample closest to a given date.
    func sample(nearestTo date: Date) -> AggregatedSample? {
        activeSamples.min(by: {
            abs($0.startDate.timeIntervalSince(date)) < abs($1.startDate.timeIntervalSince(date))
        })
    }
}
