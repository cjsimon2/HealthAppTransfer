import XCTest
@testable import HealthAppTransfer

// MARK: - Pairing ViewModel Tests

@MainActor
final class PairingViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel() -> PairingViewModel {
        let keychain = KeychainStore()
        let pairingService = PairingService(keychain: keychain)
        let certificateService = CertificateService(keychain: keychain)
        let healthKitService = HealthKitService(store: MockHealthStore())
        let auditService = AuditService()
        let biometricService = BiometricService()

        let networkServer = NetworkServer(
            healthKitService: healthKitService,
            pairingService: pairingService,
            auditService: auditService,
            certificateService: certificateService,
            biometricService: biometricService
        )

        return PairingViewModel(
            pairingService: pairingService,
            certificateService: certificateService,
            networkServer: networkServer
        )
    }

    private func makeValidPayloadJSON(expired: Bool = false) -> String {
        let expiry: TimeInterval = expired
            ? Date().timeIntervalSince1970 - 60
            : Date().timeIntervalSince1970 + 300

        let payload = QRPairingPayload(
            host: "192.168.1.100",
            port: 8443,
            fingerprint: "abc123def456",
            code: "123456",
            expiry: expiry
        )
        return payload.toJSON()!
    }

    // MARK: - Initial State

    func testInitialStateIsPairingFalse() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isPairing)
    }

    func testInitialStatePairingSuccessFalse() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.pairingSuccess)
    }

    func testInitialStateScannedPayloadNil() {
        let vm = makeViewModel()
        XCTAssertNil(vm.scannedPayload)
    }

    func testInitialStateScanErrorNil() {
        let vm = makeViewModel()
        XCTAssertNil(vm.scanError)
    }

    // MARK: - parseClipboard with Valid JSON

    func testParseClipboardWithValidJSONSetsScannedPayload() {
        let vm = makeViewModel()
        let json = makeValidPayloadJSON()

        vm.parseClipboard(json)

        XCTAssertNotNil(vm.scannedPayload)
        XCTAssertNil(vm.scanError)
        XCTAssertEqual(vm.scannedPayload?.host, "192.168.1.100")
        XCTAssertEqual(vm.scannedPayload?.port, 8443)
        XCTAssertEqual(vm.scannedPayload?.code, "123456")
    }

    // MARK: - parseClipboard with Invalid String

    func testParseClipboardWithInvalidStringSetsScanError() {
        let vm = makeViewModel()

        vm.parseClipboard("not valid json")

        XCTAssertNil(vm.scannedPayload)
        XCTAssertNotNil(vm.scanError)
        XCTAssertTrue(vm.scanError!.contains("Invalid"))
    }

    func testParseClipboardWithEmptyStringSetsScanError() {
        let vm = makeViewModel()

        vm.parseClipboard("")

        XCTAssertNil(vm.scannedPayload)
        XCTAssertNotNil(vm.scanError)
    }

    // MARK: - parseClipboard with Expired Payload

    func testParseClipboardWithExpiredPayloadSetsScanError() {
        let vm = makeViewModel()
        let json = makeValidPayloadJSON(expired: true)

        vm.parseClipboard(json)

        XCTAssertNil(vm.scannedPayload)
        XCTAssertNotNil(vm.scanError)
        XCTAssertTrue(vm.scanError!.contains("expired"))
    }

    // MARK: - handleScannedQRCode

    func testHandleScannedQRCodeDelegatesToParseClipboard() {
        let vm = makeViewModel()
        let json = makeValidPayloadJSON()

        vm.handleScannedQRCode(json)

        XCTAssertNotNil(vm.scannedPayload)
        XCTAssertEqual(vm.scannedPayload?.code, "123456")
    }

    func testHandleScannedQRCodeWithInvalidStringSetsError() {
        let vm = makeViewModel()

        vm.handleScannedQRCode("garbage")

        XCTAssertNil(vm.scannedPayload)
        XCTAssertNotNil(vm.scanError)
    }

    // MARK: - parseClipboard Clears Previous Error

    func testParseClipboardClearsPreviousError() {
        let vm = makeViewModel()

        // First, set an error
        vm.parseClipboard("invalid")
        XCTAssertNotNil(vm.scanError)

        // Then parse valid data
        let json = makeValidPayloadJSON()
        vm.parseClipboard(json)

        XCTAssertNil(vm.scanError)
        XCTAssertNotNil(vm.scannedPayload)
    }

    // MARK: - TLSPinningDelegate

    func testTLSPinningDelegateStoresExpectedFingerprint() {
        let fingerprint = "abc123def456789"
        let delegate = TLSPinningDelegate(expectedFingerprint: fingerprint)
        XCTAssertEqual(delegate.expectedFingerprint, fingerprint)
    }

    func testTLSPinningDelegateWithDifferentFingerprints() {
        let delegate1 = TLSPinningDelegate(expectedFingerprint: "aaa")
        let delegate2 = TLSPinningDelegate(expectedFingerprint: "bbb")
        XCTAssertNotEqual(delegate1.expectedFingerprint, delegate2.expectedFingerprint)
    }
}
