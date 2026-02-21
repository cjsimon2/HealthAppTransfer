import XCTest
@testable import HealthAppTransfer

final class MQTTAutomationTests: XCTestCase {

    // MARK: - MQTTAutomationError

    func testConnectionFailedErrorDescription() {
        let error = MQTTAutomationError.connectionFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testConnectionRejectedErrorDescription() {
        let error = MQTTAutomationError.connectionRejected("bad credentials")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("bad credentials"))
    }

    func testNotConnectedErrorDescription() {
        let error = MQTTAutomationError.notConnected
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testNoTypesConfiguredErrorDescription() {
        let error = MQTTAutomationError.noTypesConfigured
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testPublishFailedErrorDescription() {
        let error = MQTTAutomationError.publishFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testEncodingFailedErrorDescription() {
        let error = MQTTAutomationError.encodingFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testAllErrorCasesHaveNonNilDescription() {
        let errors: [MQTTAutomationError] = [
            .connectionFailed,
            .connectionRejected("reason"),
            .notConnected,
            .noTypesConfigured,
            .publishFailed,
            .encodingFailed
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have errorDescription")
        }
    }

    // MARK: - MQTTConnectionState.ConnectionStatus

    func testConnectionStatusRawValues() {
        XCTAssertEqual(MQTTConnectionState.ConnectionStatus.disconnected.rawValue, "Disconnected")
        XCTAssertEqual(MQTTConnectionState.ConnectionStatus.connecting.rawValue, "Connecting")
        XCTAssertEqual(MQTTConnectionState.ConnectionStatus.connected.rawValue, "Connected")
    }

    // MARK: - MQTTPushParameters Sendable Conformance

    func testMQTTPushParametersIsSendable() {
        let _: any Sendable.Type = MQTTPushParameters.self
    }
}
