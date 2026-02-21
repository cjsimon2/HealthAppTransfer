import XCTest
@testable import HealthAppTransfer

final class AutomationExecutorTests: XCTestCase {

    // MARK: - Initialization

    func testAutomationExecutorCanBeInitialized() {
        // AutomationExecutor requires HealthKitService which needs HKHealthStore.
        // Verify it can be constructed without crashing.
        let healthKitService = HealthKitService()
        let executor = AutomationExecutor(healthKitService: healthKitService)
        XCTAssertNotNil(executor)
    }

    func testAutomationExecutorAcceptsCustomKeychain() {
        let healthKitService = HealthKitService()
        let keychain = KeychainStore()
        let executor = AutomationExecutor(healthKitService: healthKitService, keychain: keychain)
        XCTAssertNotNil(executor)
    }

    // MARK: - Sendable Conformance

    func testAutomationExecutorIsSendable() {
        // Compile-time check that AutomationExecutor (actor) is Sendable
        let _: any Sendable.Type = AutomationExecutor.self
    }
}
