import XCTest
@testable import HealthAppTransfer

final class CertificateServiceTests: XCTestCase {

    // MARK: - CertificateError

    func testIdentityCreationFailedHasDescription() {
        let error = CertificateError.identityCreationFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testKeyConversionFailedWithNilHasDescription() {
        let error = CertificateError.keyConversionFailed(nil)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("unknown"))
    }

    func testKeyConversionFailedWithErrorIncludesErrorDescription() {
        let underlying = NSError(domain: "test", code: 42, userInfo: [
            NSLocalizedDescriptionKey: "test key error"
        ])
        let error = CertificateError.keyConversionFailed(underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("test key error"))
    }

    func testCertificateCreationFailedHasDescription() {
        let error = CertificateError.certificateCreationFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }
}
