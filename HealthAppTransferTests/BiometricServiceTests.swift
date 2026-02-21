import XCTest
@testable import HealthAppTransfer

final class BiometricServiceTests: XCTestCase {

    // MARK: - Properties

    private var sut: BiometricService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        sut = BiometricService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - BiometricType Enum

    func testBiometricTypeCasesExist() {
        let faceID = BiometricService.BiometricType.faceID
        let touchID = BiometricService.BiometricType.touchID
        let none = BiometricService.BiometricType.none

        XCTAssertNotNil(faceID)
        XCTAssertNotNil(touchID)
        XCTAssertNotNil(none)
    }

    // MARK: - BiometricError Descriptions

    func testNotAvailableErrorDescription() {
        let error = BiometricService.BiometricError.notAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testFailedErrorDescription() {
        let error = BiometricService.BiometricError.failed("test reason")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.errorDescription, "test reason")
    }

    func testCancelledErrorDescription() {
        let error = BiometricService.BiometricError.cancelled
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testAllBiometricErrorCasesHaveDescription() {
        let errors: [BiometricService.BiometricError] = [
            .notAvailable,
            .failed("reason"),
            .cancelled
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have errorDescription")
        }
    }

    // MARK: - Initial State

    func testInitialStateIsLocked() async {
        let isUnlocked = await sut.isUnlocked
        XCTAssertFalse(isUnlocked)
    }

    // MARK: - Lock

    func testLockSetsIsUnlockedToFalse() async {
        // First unlock
        await sut.unlockWithoutAuth()
        let unlocked = await sut.isUnlocked
        XCTAssertTrue(unlocked)

        // Then lock
        await sut.lock()
        let locked = await sut.isUnlocked
        XCTAssertFalse(locked)
    }

    // MARK: - Unlock Without Auth

    func testUnlockWithoutAuthSetsIsUnlockedToTrue() async {
        await sut.unlockWithoutAuth()
        let isUnlocked = await sut.isUnlocked
        XCTAssertTrue(isUnlocked)
    }

    // MARK: - Biometric Name

    func testBiometricNameReturnsNonEmptyString() {
        // biometricName depends on the device, but should always return something
        let name = sut.biometricName
        XCTAssertFalse(name.isEmpty)
    }

    func testBiometricNameIsOneOfExpectedValues() {
        let name = sut.biometricName
        let expectedNames = ["Face ID", "Touch ID", "Passcode"]
        XCTAssertTrue(expectedNames.contains(name), "biometricName '\(name)' should be one of \(expectedNames)")
    }
}
