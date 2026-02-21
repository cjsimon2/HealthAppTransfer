import XCTest
@testable import HealthAppTransfer

// MARK: - Health Data Detail ViewModel Tests

@MainActor
final class HealthDataDetailViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel() -> HealthDataDetailViewModel {
        let store = MockHealthStore()
        let service = HealthKitService(store: store)
        let engine = AggregationEngine(store: store)
        return HealthDataDetailViewModel(
            dataType: .stepCount,
            healthKitService: service,
            aggregationEngine: engine
        )
    }

    private func makeSample(
        sum: Double? = nil,
        average: Double? = nil,
        min: Double? = nil,
        max: Double? = nil,
        latest: Double? = nil,
        count: Int = 1,
        unit: String = "count"
    ) -> AggregatedSample {
        AggregatedSample(
            startDate: Date(),
            endDate: Date(),
            sum: sum,
            average: average,
            min: min,
            max: max,
            latest: latest,
            count: count,
            unit: unit
        )
    }

    // MARK: - Init

    func testDataTypeIsSetFromInit() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.dataType, .stepCount)
    }

    // MARK: - Latest Value

    func testLatestValueReturnsDashWhenSamplesEmpty() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.latestValue, "\u{2014}")
    }

    func testLatestValueReturnsFormattedValueWhenSamplesHaveActiveData() {
        let vm = makeViewModel()
        vm.samples = [makeSample(sum: 5000, count: 1, unit: "count")]
        XCTAssertEqual(vm.latestValue, "5000 count")
    }

    func testLatestValueUsesAverageWhenNoSum() {
        let vm = makeViewModel()
        vm.samples = [makeSample(average: 72.5, count: 1, unit: "bpm")]
        XCTAssertEqual(vm.latestValue, "72.5 bpm")
    }

    func testLatestValueSkipsZeroCountSamples() {
        let vm = makeViewModel()
        vm.samples = [
            makeSample(sum: 100, count: 1, unit: "count"),
            makeSample(sum: 200, count: 0, unit: "count")
        ]
        // last(where: count > 0) should find the first sample
        XCTAssertEqual(vm.latestValue, "100 count")
    }

    // MARK: - Min / Max / Avg

    func testMinValueReturnsDashWhenEmpty() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.minValue, "\u{2014}")
    }

    func testMaxValueReturnsDashWhenEmpty() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.maxValue, "\u{2014}")
    }

    func testAvgValueReturnsDashWhenEmpty() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.avgValue, "\u{2014}")
    }

    func testMinValueReturnsMinOfAllMinValues() {
        let vm = makeViewModel()
        vm.samples = [
            makeSample(min: 60, unit: "bpm"),
            makeSample(min: 55, unit: "bpm"),
            makeSample(min: 70, unit: "bpm")
        ]
        XCTAssertEqual(vm.minValue, "55 bpm")
    }

    func testMaxValueReturnsMaxOfAllMaxValues() {
        let vm = makeViewModel()
        vm.samples = [
            makeSample(max: 120, unit: "bpm"),
            makeSample(max: 180, unit: "bpm"),
            makeSample(max: 150, unit: "bpm")
        ]
        XCTAssertEqual(vm.maxValue, "180 bpm")
    }

    func testAvgValueReturnsAverageOfAllAverageValues() {
        let vm = makeViewModel()
        vm.samples = [
            makeSample(average: 60, unit: "bpm"),
            makeSample(average: 80, unit: "bpm"),
            makeSample(average: 100, unit: "bpm")
        ]
        XCTAssertEqual(vm.avgValue, "80 bpm")
    }

    // MARK: - Display Unit

    func testDisplayUnitReturnsEmptyWhenNoSamples() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.displayUnit, "")
    }

    func testDisplayUnitReturnsUnitFromFirstSample() {
        let vm = makeViewModel()
        vm.samples = [makeSample(unit: "kcal")]
        XCTAssertEqual(vm.displayUnit, "kcal")
    }

    // MARK: - Export JSON

    func testExportJSONReturnsNilWhenRecentDTOsEmpty() {
        let vm = makeViewModel()
        XCTAssertNil(vm.exportJSON())
    }

    func testExportJSONReturnsValidJSONWhenRecentDTOsHasData() {
        let vm = makeViewModel()
        let dto = HealthSampleDTO(
            id: UUID(),
            type: .stepCount,
            startDate: Date(),
            endDate: Date(),
            sourceName: "Test",
            sourceBundleIdentifier: nil,
            value: 100,
            unit: "count",
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: nil
        )
        vm.recentDTOs = [dto]

        let data = vm.exportJSON()
        XCTAssertNotNil(data)

        // Verify it's valid JSON
        let decoded = try? JSONSerialization.jsonObject(with: data!) as? [[String: Any]]
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.count, 1)
    }

    // MARK: - Formatting

    func testFormattedValueUsesIntegerForWholeNumbers() {
        let vm = makeViewModel()
        vm.samples = [makeSample(sum: 1000, count: 1, unit: "steps")]
        XCTAssertEqual(vm.latestValue, "1000 steps")
    }

    func testFormattedValueUsesOneDecimalForFractions() {
        let vm = makeViewModel()
        vm.samples = [makeSample(sum: 72.3, count: 1, unit: "kg")]
        XCTAssertEqual(vm.latestValue, "72.3 kg")
    }
}
