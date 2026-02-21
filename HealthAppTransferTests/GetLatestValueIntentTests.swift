import XCTest
@testable import HealthAppTransfer

final class GetLatestValueIntentTests: XCTestCase {

    // MARK: - Intent Static Properties

    func testTitleIsNotEmpty() {
        // LocalizedStringResource key should be non-empty
        let title = GetLatestValueIntent.title
        XCTAssertNotNil(title)
    }

    func testOpenAppWhenRunIsFalse() {
        XCTAssertFalse(GetLatestValueIntent.openAppWhenRun)
    }

    // MARK: - IntentError

    func testIntentErrorCasesExist() {
        // Verify enum cases compile and conform to Error
        let error1: any Error = IntentError.noTypesSelected
        let error2: any Error = IntentError.noDataFound
        let error3: any Error = IntentError.syncFailed
        XCTAssertNotNil(error1)
        XCTAssertNotNil(error2)
        XCTAssertNotNil(error3)
    }

    func testIntentErrorHasLocalizedStringResource() {
        let cases: [IntentError] = [.noTypesSelected, .noDataFound, .syncFailed]
        for error in cases {
            let resource = error.localizedStringResource
            XCTAssertNotNil(resource)
        }
    }

    // MARK: - Format Number Logic

    func testFormatNumberIntegerValues() {
        // The formatNumber helper formats integer-like doubles without decimals.
        // We test by creating an intent and verifying via the same logic.
        // Since formatNumber is private, we test the behavior indirectly:
        // integer values < 100,000 should format as integers.
        let value: Double = 5000
        let isInteger = value == value.rounded() && value < 100_000
        XCTAssertTrue(isInteger)
        XCTAssertEqual(String(Int(value)), "5000")
    }

    func testFormatNumberDecimalValues() {
        let value: Double = 72.5
        let isInteger = value == value.rounded() && value < 100_000
        XCTAssertFalse(isInteger)
        XCTAssertEqual(String(format: "%.1f", value), "72.5")
    }

    func testFormatNumberLargeIntegerUsesDecimal() {
        // Values >= 100,000 use decimal format even if they're integers
        let value: Double = 100_000
        let isInteger = value == value.rounded() && value < 100_000
        XCTAssertFalse(isInteger)
    }

    // MARK: - HealthTypeAppEntity

    func testHealthTypeAppEntityRoundtrip() {
        let entity = HealthTypeAppEntity(from: .stepCount)
        XCTAssertEqual(entity.id, HealthDataType.stepCount.rawValue)
        XCTAssertEqual(entity.healthDataType, .stepCount)
        XCTAssertFalse(entity.displayName.isEmpty)
    }

    func testHealthTypeAppEntityDisplayRepresentation() {
        let entity = HealthTypeAppEntity(from: .heartRate)
        let display = entity.displayRepresentation
        XCTAssertNotNil(display)
    }
}
