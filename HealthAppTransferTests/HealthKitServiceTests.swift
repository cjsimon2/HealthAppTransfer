import XCTest
import HealthKit
@testable import HealthAppTransfer

// MARK: - Mock Health Store

final class MockHealthStore: HealthStoreProtocol, @unchecked Sendable {

    // MARK: - Configuration

    var dataExistsResults: [HKSampleType: Bool] = [:]
    var dataExistsError: Error?
    var authorizationError: Error?
    var aggregatedStatisticsResults: [AggregatedSample] = []
    var aggregatedStatisticsError: Error?

    // MARK: - HealthStoreProtocol

    func requestAuthorization(toShare: Set<HKSampleType>?, read: Set<HKObjectType>?) async throws {
        if let error = authorizationError { throw error }
    }

    func execute(_ query: HKQuery) {
        // Not used by the optimized sampleCount path
    }

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

final class HealthKitServiceTests: XCTestCase {

    // MARK: - Quantity Type Counting

    func testSampleCountReturnsOneForQuantityTypeWithData() async throws {
        let store = MockHealthStore()
        store.dataExistsResults[HealthDataType.stepCount.sampleType] = true

        let service = HealthKitService(store: store)
        let count = try await service.sampleCount(for: .stepCount)

        XCTAssertEqual(count, 1)
    }

    func testSampleCountReturnsZeroForQuantityTypeWithoutData() async throws {
        let store = MockHealthStore()
        store.dataExistsResults[HealthDataType.heartRate.sampleType] = false

        let service = HealthKitService(store: store)
        let count = try await service.sampleCount(for: .heartRate)

        XCTAssertEqual(count, 0)
    }

    // MARK: - Category Type Counting

    func testSampleCountReturnsOneForCategoryTypeWithData() async throws {
        let store = MockHealthStore()
        store.dataExistsResults[HealthDataType.sleepAnalysis.sampleType] = true

        let service = HealthKitService(store: store)
        let count = try await service.sampleCount(for: .sleepAnalysis)

        XCTAssertEqual(count, 1)
    }

    func testSampleCountReturnsZeroForCategoryTypeWithoutData() async throws {
        let store = MockHealthStore()

        let service = HealthKitService(store: store)
        let count = try await service.sampleCount(for: .sleepAnalysis)

        XCTAssertEqual(count, 0)
    }

    // MARK: - Workout Type Counting

    func testSampleCountReturnsOneForWorkoutTypeWithData() async throws {
        let store = MockHealthStore()
        store.dataExistsResults[HealthDataType.workout.sampleType] = true

        let service = HealthKitService(store: store)
        let count = try await service.sampleCount(for: .workout)

        XCTAssertEqual(count, 1)
    }

    func testSampleCountReturnsZeroForWorkoutTypeWithoutData() async throws {
        let store = MockHealthStore()

        let service = HealthKitService(store: store)
        let count = try await service.sampleCount(for: .workout)

        XCTAssertEqual(count, 0)
    }

    // MARK: - Error Handling

    func testSampleCountPropagatesErrors() async {
        let store = MockHealthStore()
        store.dataExistsError = NSError(domain: "test", code: 42)

        let service = HealthKitService(store: store)

        do {
            _ = try await service.sampleCount(for: .stepCount)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 42)
        }
    }

    // MARK: - Available Types

    func testAvailableTypesReturnsOnlyTypesWithData() async {
        let store = MockHealthStore()
        store.dataExistsResults[HealthDataType.stepCount.sampleType] = true
        store.dataExistsResults[HealthDataType.heartRate.sampleType] = false
        store.dataExistsResults[HealthDataType.sleepAnalysis.sampleType] = true
        store.dataExistsResults[HealthDataType.workout.sampleType] = true

        let service = HealthKitService(store: store)
        let available = await service.availableTypes()
        let typeNames = available.map(\.type)

        XCTAssertTrue(typeNames.contains(.stepCount))
        XCTAssertTrue(typeNames.contains(.sleepAnalysis))
        XCTAssertTrue(typeNames.contains(.workout))
        XCTAssertFalse(typeNames.contains(.heartRate))
    }

    func testAvailableTypesReturnsEmptyWhenNoData() async {
        let store = MockHealthStore()
        // All types default to false

        let service = HealthKitService(store: store)
        let available = await service.availableTypes()

        XCTAssertTrue(available.isEmpty)
    }

    // MARK: - HealthDataType isQuantityType

    func testIsQuantityTypeIdentifiesCorrectly() {
        // Quantity types
        XCTAssertTrue(HealthDataType.stepCount.isQuantityType)
        XCTAssertTrue(HealthDataType.heartRate.isQuantityType)
        XCTAssertTrue(HealthDataType.bodyMass.isQuantityType)
        XCTAssertTrue(HealthDataType.vo2Max.isQuantityType)

        // Non-quantity types
        XCTAssertFalse(HealthDataType.sleepAnalysis.isQuantityType)
        XCTAssertFalse(HealthDataType.workout.isQuantityType)
    }
}
