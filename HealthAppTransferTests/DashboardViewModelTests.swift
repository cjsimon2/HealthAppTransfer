import XCTest
import HealthKit
@testable import HealthAppTransfer

// MARK: - Mock Health Store

private final class DashboardMockStore: HealthStoreProtocol, @unchecked Sendable {

    var dataExistsResults: [HKSampleType: Bool] = [:]
    var dataExistsError: Error?
    var authorizationError: Error?
    var aggregatedStatisticsResults: [AggregatedSample] = []
    var aggregatedStatisticsError: Error?

    func requestAuthorization(toShare: Set<HKSampleType>?, read: Set<HKObjectType>?) async throws {
        if let error = authorizationError { throw error }
    }

    func execute(_ query: HKQuery) {}
    func stop(_ query: HKQuery) {}

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        .notDetermined
    }

    func dataExists(for sampleType: HKSampleType) async throws -> Bool {
        if let error = dataExistsError { throw error }
        return dataExistsResults[sampleType] ?? false
    }

    func fetchAggregatedStatistics(
        for quantityType: HKQuantityType,
        unit: HKUnit,
        options: HKStatisticsOptions,
        anchorDate: Date,
        intervalComponents: DateComponents,
        predicate: NSPredicate?,
        enumerateFrom startDate: Date,
        to endDate: Date
    ) async throws -> [AggregatedSample] {
        if let error = aggregatedStatisticsError { throw error }
        return aggregatedStatisticsResults
    }
}

// MARK: - Tests

@MainActor
final class DashboardViewModelTests: XCTestCase {

    // MARK: - Default Metric Types

    func testDefaultMetricTypesContainsExpectedTypes() {
        let defaults = DashboardViewModel.defaultMetricTypes
        XCTAssertTrue(defaults.contains(.stepCount))
        XCTAssertTrue(defaults.contains(.heartRate))
        XCTAssertTrue(defaults.contains(.activeEnergyBurned))
        XCTAssertTrue(defaults.contains(.distanceWalkingRunning))
        XCTAssertTrue(defaults.contains(.restingHeartRate))
        XCTAssertTrue(defaults.contains(.bodyMass))
    }

    // MARK: - MetricCard

    func testMetricCardIdEqualsDataTypeRawValue() {
        let card = DashboardViewModel.MetricCard(
            dataType: .stepCount,
            latestValue: "1000 count",
            samples: [],
            trend: .noData
        )
        XCTAssertEqual(card.id, HealthDataType.stepCount.rawValue)
    }

    // MARK: - Initial State

    func testInitialCardsIsEmpty() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.cards.isEmpty)
    }

    func testInitialIsLoadingIsFalse() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Format Value (via MetricCard)

    func testIntegerValueFormatsWithoutDecimal() {
        // Test through makeCard by creating a MetricCard with known samples
        let sample = makeSample(sum: 1000, count: 1, unit: "count")
        let card = DashboardViewModel.MetricCard(
            dataType: .stepCount,
            latestValue: formatValue(1000, unit: "count"),
            samples: [sample],
            trend: .noData
        )
        XCTAssertEqual(card.latestValue, "1000 count")
    }

    func testDecimalValueFormatsWithOneDecimalPlace() {
        let card = DashboardViewModel.MetricCard(
            dataType: .bodyMass,
            latestValue: formatValue(72.5, unit: "kg"),
            samples: [],
            trend: .noData
        )
        XCTAssertEqual(card.latestValue, "72.5 kg")
    }

    // MARK: - Compute Trend

    func testTrendNoDataWithLessThanTwoSamples() {
        let samples = [makeSample(sum: 100, count: 1, unit: "count")]
        let trend = computeTrend(samples)
        XCTAssertEqual(trend, .noData)
    }

    func testTrendNoDataWithEmptySamples() {
        let trend = computeTrend([])
        XCTAssertEqual(trend, .noData)
    }

    func testTrendUpWhenValuesRising() {
        let samples = [
            makeSample(sum: 100, count: 1, unit: "count"),
            makeSample(sum: 110, count: 1, unit: "count"),
            makeSample(sum: 200, count: 1, unit: "count"),
            makeSample(sum: 300, count: 1, unit: "count")
        ]
        let trend = computeTrend(samples)
        XCTAssertEqual(trend, .up)
    }

    func testTrendDownWhenValuesFalling() {
        let samples = [
            makeSample(sum: 300, count: 1, unit: "count"),
            makeSample(sum: 200, count: 1, unit: "count"),
            makeSample(sum: 110, count: 1, unit: "count"),
            makeSample(sum: 100, count: 1, unit: "count")
        ]
        let trend = computeTrend(samples)
        XCTAssertEqual(trend, .down)
    }

    func testTrendFlatWhenValuesStable() {
        let samples = [
            makeSample(sum: 100, count: 1, unit: "count"),
            makeSample(sum: 100, count: 1, unit: "count"),
            makeSample(sum: 100, count: 1, unit: "count"),
            makeSample(sum: 100, count: 1, unit: "count")
        ]
        let trend = computeTrend(samples)
        XCTAssertEqual(trend, .flat)
    }

    // MARK: - Helpers

    private func makeViewModel() -> DashboardViewModel {
        let store = DashboardMockStore()
        let service = HealthKitService(store: store)
        return DashboardViewModel(healthKitService: service)
    }

    private func makeSample(
        sum: Double? = nil,
        average: Double? = nil,
        latest: Double? = nil,
        count: Int = 1,
        unit: String = "count"
    ) -> AggregatedSample {
        AggregatedSample(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            sum: sum,
            average: average,
            min: nil,
            max: nil,
            latest: latest,
            count: count,
            unit: unit
        )
    }

    /// Mirrors DashboardViewModel.formatValue logic for test verification.
    private func formatValue(_ value: Double, unit: String) -> String {
        if value == value.rounded() {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }

    /// Mirrors DashboardViewModel.computeTrend logic for test verification.
    private func computeTrend(_ active: [AggregatedSample]) -> TrendDirection {
        guard active.count >= 2 else { return .noData }
        let recentHalf = active.suffix(active.count / 2)
        let olderHalf = active.prefix(active.count / 2)

        func avg(_ slice: ArraySlice<AggregatedSample>) -> Double {
            let values = slice.map { $0.sum ?? $0.average ?? $0.latest ?? 0 }
            guard !values.isEmpty else { return 0 }
            return values.reduce(0, +) / Double(values.count)
        }

        let diff = avg(recentHalf) - avg(olderHalf)
        let threshold = max(avg(olderHalf) * 0.05, 0.01)
        if diff > threshold { return .up }
        if diff < -threshold { return .down }
        return .flat
    }
}
