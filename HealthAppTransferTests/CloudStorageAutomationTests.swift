import XCTest
@testable import HealthAppTransfer

final class CloudStorageAutomationTests: XCTestCase {

    // MARK: - CloudStorageError

    func testICloudUnavailableErrorDescription() {
        let error = CloudStorageError.iCloudUnavailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("iCloud"))
    }

    func testNoTypesConfiguredErrorDescription() {
        let error = CloudStorageError.noTypesConfigured
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testNoDataErrorDescription() {
        let error = CloudStorageError.noData
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testAllErrorCasesHaveNonNilDescription() {
        let errors: [CloudStorageError] = [
            .iCloudUnavailable,
            .noTypesConfigured,
            .noData
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have errorDescription")
        }
    }

    // MARK: - CloudStorageParameters Sendable Conformance

    func testCloudStorageParametersIsSendable() {
        let _: any Sendable.Type = CloudStorageParameters.self
    }
}
