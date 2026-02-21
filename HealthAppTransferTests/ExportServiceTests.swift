import XCTest
@testable import HealthAppTransfer

final class ExportServiceTests: XCTestCase {

    // MARK: - ExportFormat.displayName

    func testDisplayNameForAllCases() {
        XCTAssertEqual(ExportFormat.jsonV1.displayName, "JSON (Flat)")
        XCTAssertEqual(ExportFormat.jsonV2.displayName, "JSON (Grouped)")
        XCTAssertEqual(ExportFormat.csv.displayName, "CSV")
        XCTAssertEqual(ExportFormat.gpx.displayName, "GPX")
    }

    // MARK: - ExportFormat.fileExtension

    func testFileExtensionForAllCases() {
        XCTAssertEqual(ExportFormat.jsonV1.fileExtension, "json")
        XCTAssertEqual(ExportFormat.jsonV2.fileExtension, "json")
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.gpx.fileExtension, "gpx")
    }

    // MARK: - ExportFormat.mimeType

    func testMimeTypeForAllCases() {
        XCTAssertEqual(ExportFormat.jsonV1.mimeType, "application/json")
        XCTAssertEqual(ExportFormat.jsonV2.mimeType, "application/json")
        XCTAssertEqual(ExportFormat.csv.mimeType, "text/csv")
        XCTAssertEqual(ExportFormat.gpx.mimeType, "application/gpx+xml")
    }

    // MARK: - ExportProgress.fraction

    func testFractionWithZeroTotalReturnsZero() {
        let progress = ExportProgress(completedTypes: 0, totalTypes: 0, currentTypeName: nil)
        XCTAssertEqual(progress.fraction, 0)
    }

    func testFractionNormalCase() {
        let progress = ExportProgress(completedTypes: 3, totalTypes: 10, currentTypeName: "Step Count")
        XCTAssertEqual(progress.fraction, 0.3, accuracy: 0.001)
    }

    func testFractionComplete() {
        let progress = ExportProgress(completedTypes: 5, totalTypes: 5, currentTypeName: nil)
        XCTAssertEqual(progress.fraction, 1.0, accuracy: 0.001)
    }

    // MARK: - ExportError.errorDescription

    func testErrorDescriptionNoTypesSelected() {
        let error = ExportError.noTypesSelected
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("No health data types"))
    }

    func testErrorDescriptionNoDataFound() {
        let error = ExportError.noDataFound
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("No data found"))
    }

    func testErrorDescriptionGPXRequiresWorkouts() {
        let error = ExportError.gpxRequiresWorkouts
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("GPX"))
    }

    func testErrorDescriptionWriteFailed() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"])
        let error = ExportError.writeFailed(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Failed to write"))
    }

    // MARK: - ExportOptions Init Defaults

    func testExportOptionsDefaults() {
        let options = ExportOptions()
        XCTAssertNil(options.startDate)
        XCTAssertNil(options.endDate)
        XCTAssertFalse(options.prettyPrint)
        XCTAssertNil(options.deviceName)
        XCTAssertNil(options.deviceModel)
        XCTAssertNil(options.systemVersion)
        XCTAssertNil(options.appVersion)
    }
}
