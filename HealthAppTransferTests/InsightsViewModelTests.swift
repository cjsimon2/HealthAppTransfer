import HealthKit
import XCTest
@testable import HealthAppTransfer

@MainActor
final class InsightsViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialStateIsEmpty() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.insights.isEmpty)
        XCTAssertNil(vm.correlationResult)
        XCTAssertFalse(vm.isLoadingInsights)
        XCTAssertFalse(vm.isLoadingCorrelation)
    }

    // MARK: - Pearson Correlation

    func testPearsonPerfectPositiveCorrelation() {
        let vm = makeViewModel()
        let r = vm.pearsonCorrelation(xs: [1, 2, 3, 4, 5], ys: [2, 4, 6, 8, 10])
        XCTAssertEqual(r, 1.0, accuracy: 0.0001)
    }

    func testPearsonPerfectNegativeCorrelation() {
        let vm = makeViewModel()
        let r = vm.pearsonCorrelation(xs: [1, 2, 3, 4, 5], ys: [10, 8, 6, 4, 2])
        XCTAssertEqual(r, -1.0, accuracy: 0.0001)
    }

    func testPearsonUncorrelatedData() {
        let vm = makeViewModel()
        // Deliberately uncorrelated: alternating pattern vs constant
        let r = vm.pearsonCorrelation(xs: [1, 2, 3, 4, 5], ys: [5, 5, 5, 5, 5])
        XCTAssertEqual(r, 0.0, accuracy: 0.0001)
    }

    func testPearsonEmptyArraysReturnsZero() {
        let vm = makeViewModel()
        let r = vm.pearsonCorrelation(xs: [], ys: [])
        XCTAssertEqual(r, 0.0)
    }

    func testPearsonMismatchedLengthsReturnsZero() {
        let vm = makeViewModel()
        let r = vm.pearsonCorrelation(xs: [1, 2, 3], ys: [1, 2])
        XCTAssertEqual(r, 0.0)
    }

    func testPearsonIdenticalValuesReturnsZero() {
        let vm = makeViewModel()
        let r = vm.pearsonCorrelation(xs: [3, 3, 3], ys: [7, 7, 7])
        XCTAssertEqual(r, 0.0)
    }

    // MARK: - Correlation Strength Labels

    func testCorrelationStrengthWeak() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.correlationStrength(0.0), "Weak")
        XCTAssertEqual(vm.correlationStrength(0.29), "Weak")
        XCTAssertEqual(vm.correlationStrength(-0.1), "Weak")
    }

    func testCorrelationStrengthModerate() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.correlationStrength(0.3), "Moderate")
        XCTAssertEqual(vm.correlationStrength(0.5), "Moderate")
        XCTAssertEqual(vm.correlationStrength(0.69), "Moderate")
        XCTAssertEqual(vm.correlationStrength(-0.5), "Moderate")
    }

    func testCorrelationStrengthStrong() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.correlationStrength(0.7), "Strong")
        XCTAssertEqual(vm.correlationStrength(1.0), "Strong")
        XCTAssertEqual(vm.correlationStrength(-0.8), "Strong")
    }

    // MARK: - Suggested Pairs

    func testSuggestedPairsAreNotEmpty() {
        XCTAssertFalse(InsightsViewModel.suggestedPairs.isEmpty)
    }

    func testSuggestedPairsContainQuantityTypes() {
        for (a, b) in InsightsViewModel.suggestedPairs {
            XCTAssertTrue(a.isQuantityType, "\(a.displayName) should be a quantity type")
            XCTAssertTrue(b.isQuantityType, "\(b.displayName) should be a quantity type")
        }
    }

    // MARK: - Default Insight Types

    func testDefaultInsightTypesAreQuantityTypes() {
        for type in InsightsViewModel.defaultInsightTypes {
            XCTAssertTrue(type.isQuantityType, "\(type.displayName) should be a quantity type")
        }
    }

    func testDefaultInsightTypesIncludesAppleExerciseTime() {
        XCTAssertTrue(InsightsViewModel.defaultInsightTypes.contains(.appleExerciseTime))
    }

    // MARK: - Streak Thresholds

    func testStreakThresholdsContainExpectedTypes() {
        let types = InsightsViewModel.streakThresholds.keys
        XCTAssertTrue(types.contains(.stepCount))
        XCTAssertTrue(types.contains(.activeEnergyBurned))
        XCTAssertTrue(types.contains(.distanceWalkingRunning))
        XCTAssertTrue(types.contains(.appleExerciseTime))
    }

    func testStreakThresholdValuesArePositive() {
        for (_, config) in InsightsViewModel.streakThresholds {
            XCTAssertGreaterThan(config.threshold, 0)
            XCTAssertFalse(config.unit.isEmpty)
        }
    }

    // MARK: - Daily Goals

    func testDailyGoalsContainExpectedTypes() {
        let types = InsightsViewModel.dailyGoals.keys
        XCTAssertTrue(types.contains(.stepCount))
        XCTAssertTrue(types.contains(.activeEnergyBurned))
        XCTAssertTrue(types.contains(.distanceWalkingRunning))
        XCTAssertTrue(types.contains(.appleExerciseTime))
    }

    func testDailyGoalValuesArePositive() {
        for (_, config) in InsightsViewModel.dailyGoals {
            XCTAssertGreaterThan(config.goal, 0)
            XCTAssertFalse(config.unit.isEmpty)
        }
    }

    // MARK: - Favorites

    func testIsFavoriteDefaultsFalse() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isFavorite(typeA: .stepCount, typeB: .heartRate))
    }

    func testOrderedSuggestedPairsCountMatchesSuggestedPairs() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.orderedSuggestedPairs().count, InsightsViewModel.suggestedPairs.count)
    }

    // MARK: - Helpers

    private func makeViewModel() -> InsightsViewModel {
        let service = HealthKitService(store: InsightsMockStore())
        return InsightsViewModel(healthKitService: service)
    }
}

// MARK: - Mock Health Store

private final class InsightsMockStore: HealthStoreProtocol, @unchecked Sendable {

    func requestAuthorization(toShare: Set<HKSampleType>?, read: Set<HKObjectType>?) async throws {}
    func execute(_ query: HKQuery) {}
    func stop(_ query: HKQuery) {}

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        .notDetermined
    }

    func dataExists(for sampleType: HKSampleType) async throws -> Bool {
        false
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
        []
    }
}
