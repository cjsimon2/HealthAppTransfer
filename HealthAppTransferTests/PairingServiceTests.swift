import XCTest
@testable import HealthAppTransfer

final class PairingServiceTests: XCTestCase {

    // MARK: - Properties

    private var sut: PairingService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        sut = PairingService(keychain: KeychainStore())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Code Generation

    func testGeneratePairingCodeReturns6DigitCode() async {
        let pairingCode = await sut.generatePairingCode()

        XCTAssertEqual(pairingCode.code.count, 6)
        XCTAssertTrue(pairingCode.code.allSatisfy(\.isNumber))
    }

    func testGeneratePairingCodeReturnsNonEmptyToken() async {
        let pairingCode = await sut.generatePairingCode()

        XCTAssertFalse(pairingCode.token.isEmpty)
    }

    func testGeneratePairingCodeReturnsFutureExpiry() async {
        let pairingCode = await sut.generatePairingCode()

        XCTAssertGreaterThan(pairingCode.expiresAt, Date())
    }

    // MARK: - Code Validation

    func testValidateCodeWithValidCodeReturnsToken() async {
        let pairingCode = await sut.generatePairingCode()

        let token = await sut.validateCode(pairingCode.code)
        XCTAssertNotNil(token)
        XCTAssertEqual(token, pairingCode.token)
    }

    func testValidateCodeConsumesCode() async {
        let pairingCode = await sut.generatePairingCode()

        let firstAttempt = await sut.validateCode(pairingCode.code)
        XCTAssertNotNil(firstAttempt)

        let secondAttempt = await sut.validateCode(pairingCode.code)
        XCTAssertNil(secondAttempt, "Code should be consumed after first validation")
    }

    func testValidateCodeWithInvalidCodeReturnsNil() async {
        let token = await sut.validateCode("000000")
        XCTAssertNil(token)
    }

    // MARK: - Token Validation

    func testValidateTokenReturnsTrueAfterCodeValidated() async {
        let pairingCode = await sut.generatePairingCode()
        _ = await sut.validateCode(pairingCode.code)

        let isValid = await sut.validateToken(pairingCode.token)
        XCTAssertTrue(isValid)
    }

    func testValidateTokenReturnsFalseForUnknownToken() async {
        let isValid = await sut.validateToken("unknown-token")
        XCTAssertFalse(isValid)
    }

    // MARK: - Token Revocation

    func testRevokeTokenRemovesToken() async {
        let pairingCode = await sut.generatePairingCode()
        _ = await sut.validateCode(pairingCode.code)

        await sut.revokeToken(pairingCode.token)

        let isValid = await sut.validateToken(pairingCode.token)
        XCTAssertFalse(isValid)
    }

    func testRevokeAllClearsEverything() async {
        let code1 = await sut.generatePairingCode()
        let code2 = await sut.generatePairingCode()
        _ = await sut.validateCode(code1.code)
        _ = await sut.validateCode(code2.code)

        await sut.revokeAll()

        let tokenCount = await sut.validTokenCount
        let codeCount = await sut.activeCodeCount
        XCTAssertEqual(tokenCount, 0)
        XCTAssertEqual(codeCount, 0)
    }

    // MARK: - Counts

    func testActiveCodeCount() async {
        _ = await sut.generatePairingCode()
        _ = await sut.generatePairingCode()

        let count = await sut.activeCodeCount
        XCTAssertEqual(count, 2)
    }

    func testValidTokenCount() async {
        let code1 = await sut.generatePairingCode()
        let code2 = await sut.generatePairingCode()
        _ = await sut.validateCode(code1.code)
        _ = await sut.validateCode(code2.code)

        let count = await sut.validTokenCount
        XCTAssertEqual(count, 2)
    }

    // MARK: - Device Registration

    func testRegisterDeviceAndRevokeDeviceToken() async {
        let pairingCode = await sut.generatePairingCode()
        let token = await sut.validateCode(pairingCode.code)
        XCTAssertNotNil(token)

        await sut.registerDevice(deviceID: "device-1", token: token!)

        // Token should still be valid
        let isValid = await sut.validateToken(token!)
        XCTAssertTrue(isValid)

        // Revoke by device ID
        await sut.revokeDeviceToken(deviceID: "device-1")

        let isValidAfterRevoke = await sut.validateToken(token!)
        XCTAssertFalse(isValidAfterRevoke)
    }
}
