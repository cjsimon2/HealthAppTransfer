import XCTest
import HealthKit
@testable import HealthAppTransfer

// MARK: - Mock Health Store

private final class ExportMockStore: HealthStoreProtocol, @unchecked Sendable {

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
final class ExportViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialSelectedFormatIsJsonV2() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.selectedFormat, .jsonV2)
    }

    func testInitialAggregationEnabledIsFalse() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.aggregationEnabled)
    }

    func testInitialSelectedTypesIsEmpty() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.selectedTypes.isEmpty)
    }

    // MARK: - canExport

    func testCanExportIsFalseWhenSelectedTypesIsEmpty() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.canExport)
    }

    func testCanExportIsTrueWhenTypesSelectedAndNotExporting() {
        let vm = makeViewModel()
        vm.selectedTypes = [.stepCount]
        XCTAssertTrue(vm.canExport)
    }

    func testCanExportIsFalseWhenExporting() {
        let vm = makeViewModel()
        vm.selectedTypes = [.stepCount]
        vm.isExporting = true
        XCTAssertFalse(vm.canExport)
    }

    // MARK: - selectedTypeCount

    func testSelectedTypeCountMatchesSelectedTypesCount() {
        let vm = makeViewModel()
        vm.selectedTypes = [.stepCount, .heartRate, .bodyMass]
        XCTAssertEqual(vm.selectedTypeCount, 3)
    }

    func testSelectedTypeCountIsZeroWhenEmpty() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.selectedTypeCount, 0)
    }

    // MARK: - Toggle Type

    func testToggleTypeAddsType() {
        let vm = makeViewModel()
        vm.toggleType(.stepCount)
        XCTAssertTrue(vm.selectedTypes.contains(.stepCount))
    }

    func testToggleTypeRemovesExistingType() {
        let vm = makeViewModel()
        vm.selectedTypes = [.stepCount]
        vm.toggleType(.stepCount)
        XCTAssertFalse(vm.selectedTypes.contains(.stepCount))
    }

    func testToggleTypeTogglesCorrectly() {
        let vm = makeViewModel()
        vm.toggleType(.heartRate)
        XCTAssertTrue(vm.selectedTypes.contains(.heartRate))
        vm.toggleType(.heartRate)
        XCTAssertFalse(vm.selectedTypes.contains(.heartRate))
    }

    // MARK: - Select All

    func testSelectAllAddsAllAvailableTypes() {
        let vm = makeViewModel()
        vm.availableTypes = [
            (category: .activity, types: [.stepCount, .activeEnergyBurned]),
            (category: .heart, types: [.heartRate])
        ]
        vm.selectAll()
        XCTAssertEqual(vm.selectedTypes.count, 3)
        XCTAssertTrue(vm.selectedTypes.contains(.stepCount))
        XCTAssertTrue(vm.selectedTypes.contains(.activeEnergyBurned))
        XCTAssertTrue(vm.selectedTypes.contains(.heartRate))
    }

    func testSelectAllDoesNothingWhenNoAvailableTypes() {
        let vm = makeViewModel()
        vm.availableTypes = []
        vm.selectAll()
        XCTAssertTrue(vm.selectedTypes.isEmpty)
    }

    // MARK: - Deselect All

    func testDeselectAllClearsSelection() {
        let vm = makeViewModel()
        vm.selectedTypes = [.stepCount, .heartRate, .bodyMass]
        vm.deselectAll()
        XCTAssertTrue(vm.selectedTypes.isEmpty)
    }

    func testDeselectAllOnEmptyIsNoOp() {
        let vm = makeViewModel()
        vm.deselectAll()
        XCTAssertTrue(vm.selectedTypes.isEmpty)
    }

    // MARK: - Helpers

    private func makeViewModel() -> ExportViewModel {
        let store = ExportMockStore()
        let service = HealthKitService(store: store)
        return ExportViewModel(healthKitService: service)
    }
}
