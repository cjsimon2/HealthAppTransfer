import XCTest
@testable import HealthAppTransfer

final class AutomationSchedulerTests: XCTestCase {

    // MARK: - Note
    //
    // AutomationScheduler requires HKHealthStore and ModelContainer,
    // and full testing requires HealthKit entitlement.
    // These tests focus on what's testable without the full stack.

    // MARK: - Sendable Conformance

    func testAutomationSchedulerIsSendable() {
        // AutomationScheduler is an actor, which is inherently Sendable
        let _: any Sendable.Type = AutomationScheduler.self
    }

    // MARK: - AutomationExecutor Dependency

    func testAutomationExecutorIsSendable() {
        let _: any Sendable.Type = AutomationExecutor.self
    }
}
