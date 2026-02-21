import XCTest
@testable import HealthAppTransfer

final class HomeAssistantAutomationTests: XCTestCase {

    // MARK: - HomeAssistantError

    func testInvalidURLErrorDescription() {
        let error = HomeAssistantError.invalidURL
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testMissingTokenErrorDescription() {
        let error = HomeAssistantError.missingToken
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testUnauthorizedErrorDescription() {
        let error = HomeAssistantError.unauthorized
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testInvalidResponseErrorDescription() {
        let error = HomeAssistantError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testHTTPErrorIncludesStatusCode() {
        let error = HomeAssistantError.httpError(statusCode: 503)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("503"))
    }

    func testNoTypesConfiguredErrorDescription() {
        let error = HomeAssistantError.noTypesConfigured
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testAllErrorCasesHaveNonNilDescription() {
        let errors: [HomeAssistantError] = [
            .invalidURL,
            .missingToken,
            .unauthorized,
            .invalidResponse,
            .httpError(statusCode: 404),
            .noTypesConfigured
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have errorDescription")
        }
    }

    // MARK: - Entity ID Conversion

    func testEntityIdForStepCount() {
        let entityId = HomeAssistantAutomation.entityId(for: .stepCount)
        XCTAssertEqual(entityId, "sensor.health_step_count")
    }

    func testEntityIdForHeartRate() {
        let entityId = HomeAssistantAutomation.entityId(for: .heartRate)
        XCTAssertEqual(entityId, "sensor.health_heart_rate")
    }

    func testEntityIdForBodyMass() {
        let entityId = HomeAssistantAutomation.entityId(for: .bodyMass)
        XCTAssertEqual(entityId, "sensor.health_body_mass")
    }

    func testEntityIdForActiveEnergyBurned() {
        let entityId = HomeAssistantAutomation.entityId(for: .activeEnergyBurned)
        XCTAssertEqual(entityId, "sensor.health_active_energy_burned")
    }

    func testEntityIdForOxygenSaturation() {
        let entityId = HomeAssistantAutomation.entityId(for: .oxygenSaturation)
        XCTAssertEqual(entityId, "sensor.health_oxygen_saturation")
    }

    // MARK: - HomeAssistantParameters Sendable Conformance

    func testHomeAssistantParametersIsSendable() {
        let _: any Sendable.Type = HomeAssistantParameters.self
    }

    // MARK: - Keychain Key Prefix

    func testKeychainKeyPrefixIsNonEmpty() {
        XCTAssertFalse(HomeAssistantAutomation.keychainKeyPrefix.isEmpty)
        XCTAssertEqual(HomeAssistantAutomation.keychainKeyPrefix, "ha_token_")
    }
}
