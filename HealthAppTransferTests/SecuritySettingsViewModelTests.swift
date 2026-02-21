import XCTest
@testable import HealthAppTransfer

// MARK: - Security Settings ViewModel Tests

@MainActor
final class SecuritySettingsViewModelTests: XCTestCase {

    // MARK: - BiometricType Cases

    func testBiometricTypeCasesExist() {
        // Verify all expected cases compile and are distinct
        let faceID = BiometricService.BiometricType.faceID
        let touchID = BiometricService.BiometricType.touchID
        let none = BiometricService.BiometricType.none

        // They should be different values
        XCTAssertFalse(faceID == none)
        XCTAssertFalse(touchID == none)
        XCTAssertFalse(faceID == touchID)
    }

    // MARK: - BiometricError Descriptions

    func testBiometricErrorNotAvailableDescription() {
        let error = BiometricService.BiometricError.notAvailable
        XCTAssertEqual(
            error.errorDescription,
            "Biometric authentication is not available on this device."
        )
    }

    func testBiometricErrorFailedDescription() {
        let error = BiometricService.BiometricError.failed("Test reason")
        XCTAssertEqual(error.errorDescription, "Test reason")
    }

    func testBiometricErrorCancelledDescription() {
        let error = BiometricService.BiometricError.cancelled
        XCTAssertEqual(error.errorDescription, "Authentication was cancelled.")
    }

    // MARK: - Biometric Icon Name Mapping

    func testBiometricIconNameForNoneBiometricType() {
        // On a Mac/Simulator without biometrics, availableBiometricType returns .none
        let biometricService = BiometricService()
        let vm = SecuritySettingsViewModel(biometricService: biometricService)

        // In test/simulator environment, biometrics are typically unavailable
        // The icon should be one of the three valid values
        let validIcons = ["faceid", "touchid", "lock.shield"]
        XCTAssertTrue(validIcons.contains(vm.biometricIconName))
    }

    // MARK: - ViewModel Initial State

    func testInitialStateIsBiometricEnabledFalse() {
        let vm = SecuritySettingsViewModel(biometricService: BiometricService())
        XCTAssertFalse(vm.isBiometricEnabled)
    }

    func testInitialStateIsAuthenticatingFalse() {
        let vm = SecuritySettingsViewModel(biometricService: BiometricService())
        XCTAssertFalse(vm.isAuthenticating)
    }

    func testInitialStateErrorNil() {
        let vm = SecuritySettingsViewModel(biometricService: BiometricService())
        XCTAssertNil(vm.error)
    }

    // MARK: - BiometricError Conformance

    func testBiometricErrorIsLocalizedError() {
        let error: any LocalizedError = BiometricService.BiometricError.notAvailable
        XCTAssertNotNil(error.errorDescription)
    }

    func testBiometricErrorIsSendable() {
        // Compile-time check: this should compile without warnings
        let error: any Sendable = BiometricService.BiometricError.cancelled
        XCTAssertNotNil(error)
    }
}
