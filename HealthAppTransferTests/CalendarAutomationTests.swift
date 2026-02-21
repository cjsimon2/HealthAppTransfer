import XCTest
@testable import HealthAppTransfer

final class CalendarAutomationTests: XCTestCase {

    // MARK: - CalendarAutomationError

    func testAccessDeniedErrorDescription() {
        let error = CalendarAutomationError.accessDenied
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Calendar"))
    }

    func testNoWorkoutsFoundErrorDescription() {
        let error = CalendarAutomationError.noWorkoutsFound
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("workout"))
    }

    func testAllErrorCasesHaveNonNilDescription() {
        let errors: [CalendarAutomationError] = [
            .accessDenied,
            .noWorkoutsFound
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have errorDescription")
        }
    }

    // MARK: - CalendarParameters Sendable Conformance

    func testCalendarParametersIsSendable() {
        let _: any Sendable.Type = CalendarParameters.self
    }
}
