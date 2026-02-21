import XCTest
import HealthKit
@testable import HealthAppTransfer

// MARK: - Mock Health Store

private final class HealthDataViewModelMockStore: HealthStoreProtocol, @unchecked Sendable {

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
final class HealthDataViewModelTests: XCTestCase {

    // MARK: - TypeInfo

    func testTypeInfoIdEqualsTypeRawValue() {
        let info = HealthDataViewModel.TypeInfo(type: .stepCount, count: 5)
        XCTAssertEqual(info.id, HealthDataType.stepCount.rawValue)
    }

    func testTypeInfoDisplayNameMatchesTypeDisplayName() {
        let info = HealthDataViewModel.TypeInfo(type: .heartRate, count: 3)
        XCTAssertEqual(info.displayName, HealthDataType.heartRate.displayName)
    }

    // MARK: - CategoryGroup

    func testCategoryGroupTotalCountSumsTypeCounts() {
        let types = [
            HealthDataViewModel.TypeInfo(type: .stepCount, count: 10),
            HealthDataViewModel.TypeInfo(type: .activeEnergyBurned, count: 5),
            HealthDataViewModel.TypeInfo(type: .distanceWalkingRunning, count: 3)
        ]
        let group = HealthDataViewModel.CategoryGroup(category: .activity, types: types)
        XCTAssertEqual(group.totalCount, 18)
    }

    func testCategoryGroupTotalCountIsZeroWhenEmpty() {
        let group = HealthDataViewModel.CategoryGroup(category: .activity, types: [])
        XCTAssertEqual(group.totalCount, 0)
    }

    // MARK: - Filtered Groups

    func testFilteredGroupsReturnsAllGroupsWhenSearchTextIsEmpty() {
        let vm = makeViewModel()
        vm.allGroups = [
            makeGroup(category: .activity, types: [.stepCount]),
            makeGroup(category: .heart, types: [.heartRate])
        ]
        vm.searchText = ""
        XCTAssertEqual(vm.filteredGroups.count, 2)
    }

    func testFilteredGroupsFiltersByDisplayNameWhenSearchTextIsSet() {
        let vm = makeViewModel()
        vm.allGroups = [
            makeGroup(category: .activity, types: [.stepCount]),
            makeGroup(category: .heart, types: [.heartRate])
        ]
        vm.searchText = "step"

        let filtered = vm.filteredGroups
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.category, .activity)
    }

    func testFilteredGroupsReturnsEmptyWhenNoMatch() {
        let vm = makeViewModel()
        vm.allGroups = [
            makeGroup(category: .activity, types: [.stepCount])
        ]
        vm.searchText = "zzzznotfound"
        XCTAssertTrue(vm.filteredGroups.isEmpty)
    }

    // MARK: - isEmpty

    func testIsEmptyWhenAllGroupsHaveEmptyTypes() {
        let vm = makeViewModel()
        vm.allGroups = [
            HealthDataViewModel.CategoryGroup(category: .activity, types: []),
            HealthDataViewModel.CategoryGroup(category: .heart, types: [])
        ]
        XCTAssertTrue(vm.isEmpty)
    }

    func testIsNotEmptyWhenAGroupHasTypes() {
        let vm = makeViewModel()
        vm.allGroups = [
            makeGroup(category: .activity, types: [.stepCount]),
            HealthDataViewModel.CategoryGroup(category: .heart, types: [])
        ]
        XCTAssertFalse(vm.isEmpty)
    }

    // MARK: - Helpers

    private func makeViewModel() -> HealthDataViewModel {
        let store = HealthDataViewModelMockStore()
        let service = HealthKitService(store: store)
        return HealthDataViewModel(healthKitService: service)
    }

    private func makeGroup(
        category: HealthDataCategory,
        types: [HealthDataType]
    ) -> HealthDataViewModel.CategoryGroup {
        let typeInfos = types.map { HealthDataViewModel.TypeInfo(type: $0, count: 1) }
        return HealthDataViewModel.CategoryGroup(category: category, types: typeInfos)
    }
}
