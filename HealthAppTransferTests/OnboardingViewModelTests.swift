import XCTest
import HealthKit
@testable import HealthAppTransfer

// MARK: - Mock Health Store

private final class OnboardingMockStore: HealthStoreProtocol, @unchecked Sendable {

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
final class OnboardingViewModelTests: XCTestCase {

    // MARK: - Step

    func testActiveStepsContainsExpectedSteps() {
        let steps = OnboardingViewModel.Step.activeSteps
        XCTAssertTrue(steps.contains(.welcome))
        XCTAssertTrue(steps.contains(.healthKit))
        XCTAssertTrue(steps.contains(.quickSetup))
        XCTAssertFalse(steps.isEmpty)
    }

    // MARK: - Initial State

    func testInitialCurrentStepIsWelcome() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.currentStep, .welcome)
    }

    // MARK: - Navigation

    func testNextStepAdvancesThroughActiveSteps() {
        let vm = makeViewModel()
        let steps = OnboardingViewModel.Step.activeSteps

        XCTAssertEqual(vm.currentStep, steps[0])
        vm.nextStep()
        XCTAssertEqual(vm.currentStep, steps[1])
    }

    func testNextStepDoesNotAdvancePastLastStep() {
        let vm = makeViewModel()
        let steps = OnboardingViewModel.Step.activeSteps

        // Advance to last step
        for _ in 0..<steps.count {
            vm.nextStep()
        }
        let lastStep = vm.currentStep
        vm.nextStep()
        XCTAssertEqual(vm.currentStep, lastStep)
    }

    func testPreviousStepGoesBack() {
        let vm = makeViewModel()
        vm.nextStep()
        let secondStep = vm.currentStep
        vm.previousStep()
        XCTAssertNotEqual(vm.currentStep, secondStep)
        XCTAssertEqual(vm.currentStep, .welcome)
    }

    func testPreviousStepStopsAtFirstStep() {
        let vm = makeViewModel()
        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .welcome)
    }

    // MARK: - isLastStep

    func testIsLastStepIsTrueOnlyOnLastStep() {
        let vm = makeViewModel()
        let steps = OnboardingViewModel.Step.activeSteps

        XCTAssertFalse(vm.isLastStep)

        // Advance to last step
        for _ in 0..<(steps.count - 1) {
            vm.nextStep()
        }
        XCTAssertTrue(vm.isLastStep)
    }

    // MARK: - currentStepIndex

    func testCurrentStepIndexReturnsCorrectIndex() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.currentStepIndex, 0)
        vm.nextStep()
        XCTAssertEqual(vm.currentStepIndex, 1)
    }

    // MARK: - Metrics

    func testMetricsInitializedWithDefaults() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.metrics.isEmpty)
    }

    func testSomeMetricsAreSelectedByDefault() {
        let vm = makeViewModel()
        let selectedCount = vm.metrics.filter(\.isSelected).count
        XCTAssertGreaterThan(selectedCount, 0)
    }

    func testSelectedMetricCountCountsSelectedMetrics() {
        let vm = makeViewModel()
        let expectedCount = vm.metrics.filter(\.isSelected).count
        XCTAssertEqual(vm.selectedMetricCount, expectedCount)
    }

    // MARK: - Toggle Metric

    func testToggleMetricTogglesIsSelected() {
        let vm = makeViewModel()
        guard let metric = vm.metrics.first else {
            XCTFail("No metrics available")
            return
        }

        let initialState = metric.isSelected
        vm.toggleMetric(metric)

        let updatedMetric = vm.metrics.first { $0.category == metric.category }
        XCTAssertEqual(updatedMetric?.isSelected, !initialState)
    }

    func testToggleMetricTogglesBack() {
        let vm = makeViewModel()
        guard let metric = vm.metrics.first else {
            XCTFail("No metrics available")
            return
        }

        let initialState = metric.isSelected
        vm.toggleMetric(metric)
        // Refetch since struct was replaced
        let toggled = vm.metrics.first { $0.category == metric.category }!
        vm.toggleMetric(toggled)

        let final = vm.metrics.first { $0.category == metric.category }
        XCTAssertEqual(final?.isSelected, initialState)
    }

    // MARK: - Helpers

    private func makeViewModel() -> OnboardingViewModel {
        let store = OnboardingMockStore()
        let service = HealthKitService(store: store)
        return OnboardingViewModel(healthKitService: service)
    }
}
