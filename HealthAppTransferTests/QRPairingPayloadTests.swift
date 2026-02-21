import XCTest
@testable import HealthAppTransfer

final class QRPairingPayloadTests: XCTestCase {

    // MARK: - Helpers

    private func makePayload(
        host: String = "192.168.1.1",
        port: UInt16 = 8443,
        fingerprint: String = "abc123",
        code: String = "123456",
        expiry: TimeInterval = Date().timeIntervalSince1970 + 300
    ) -> QRPairingPayload {
        QRPairingPayload(
            host: host,
            port: port,
            fingerprint: fingerprint,
            code: code,
            expiry: expiry
        )
    }

    // MARK: - JSON Roundtrip

    func testToJSONAndFromJSONRoundtrip() {
        let payload = makePayload()
        let json = payload.toJSON()
        XCTAssertNotNil(json)

        let decoded = QRPairingPayload.fromJSON(json!)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded!.host, payload.host)
        XCTAssertEqual(decoded!.port, payload.port)
        XCTAssertEqual(decoded!.fingerprint, payload.fingerprint)
        XCTAssertEqual(decoded!.code, payload.code)
        XCTAssertEqual(decoded!.expiry, payload.expiry)
    }

    // MARK: - isExpired

    func testIsExpiredReturnsFalseForFutureExpiry() {
        let payload = makePayload(expiry: Date().timeIntervalSince1970 + 300)
        XCTAssertFalse(payload.isExpired)
    }

    func testIsExpiredReturnsTrueForPastExpiry() {
        let payload = makePayload(expiry: Date().timeIntervalSince1970 - 300)
        XCTAssertTrue(payload.isExpired)
    }

    // MARK: - timeRemaining

    func testTimeRemainingIsPositiveForFutureExpiry() {
        let payload = makePayload(expiry: Date().timeIntervalSince1970 + 300)
        XCTAssertGreaterThan(payload.timeRemaining, 0)
    }

    func testTimeRemainingIsZeroForPastExpiry() {
        let payload = makePayload(expiry: Date().timeIntervalSince1970 - 300)
        XCTAssertEqual(payload.timeRemaining, 0)
    }

    // MARK: - expiryDate

    func testExpiryDateMatchesExpiryTimestamp() {
        let expiry: TimeInterval = 1_700_000_000
        let payload = makePayload(expiry: expiry)
        XCTAssertEqual(payload.expiryDate, Date(timeIntervalSince1970: expiry))
    }

    // MARK: - fromJSON Invalid Input

    func testFromJSONWithInvalidStringReturnsNil() {
        XCTAssertNil(QRPairingPayload.fromJSON("not json"))
    }

    func testFromJSONWithEmptyStringReturnsNil() {
        XCTAssertNil(QRPairingPayload.fromJSON(""))
    }
}
