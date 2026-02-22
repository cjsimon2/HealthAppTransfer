import HealthKit
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

    // MARK: - Heart Rate Correlation (nearestHeartRate)

    private let bpmUnit = HKUnit.count().unitDivided(by: .minute())

    private func makeHRSample(bpm: Double, at date: Date) -> HKQuantitySample {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let quantity = HKQuantity(unit: bpmUnit, doubleValue: bpm)
        return HKQuantitySample(type: hrType, quantity: quantity, start: date, end: date)
    }

    func testNearestHeartRateReturnsNilForEmptySamples() {
        let result = ExportService.nearestHeartRate(
            for: Date(),
            in: [],
            unit: bpmUnit
        )
        XCTAssertNil(result)
    }

    func testNearestHeartRateFindsExactMatch() {
        let now = Date()
        let samples = [makeHRSample(bpm: 145, at: now)]

        let result = ExportService.nearestHeartRate(for: now, in: samples, unit: bpmUnit)
        XCTAssertEqual(result, 145)
    }

    func testNearestHeartRateFindsClosestSample() {
        let base = Date()
        let samples = [
            makeHRSample(bpm: 120, at: base.addingTimeInterval(-3)),
            makeHRSample(bpm: 145, at: base.addingTimeInterval(-1)),
            makeHRSample(bpm: 150, at: base.addingTimeInterval(2)),
        ]

        let result = ExportService.nearestHeartRate(for: base, in: samples, unit: bpmUnit)
        XCTAssertEqual(result, 145, "Should pick the sample 1 second before, not 2 seconds after")
    }

    func testNearestHeartRateReturnsNilBeyondMaxInterval() {
        let base = Date()
        let samples = [
            makeHRSample(bpm: 130, at: base.addingTimeInterval(-10)),
        ]

        let result = ExportService.nearestHeartRate(
            for: base,
            in: samples,
            unit: bpmUnit,
            maxInterval: 5.0
        )
        XCTAssertNil(result, "Sample 10s away should exceed 5s max interval")
    }

    func testNearestHeartRateRespectsCustomMaxInterval() {
        let base = Date()
        let samples = [
            makeHRSample(bpm: 130, at: base.addingTimeInterval(-8)),
        ]

        let result = ExportService.nearestHeartRate(
            for: base,
            in: samples,
            unit: bpmUnit,
            maxInterval: 10.0
        )
        XCTAssertEqual(result, 130, "Sample 8s away should be within 10s max interval")
    }

    func testNearestHeartRatePicksCloserOfTwoSurroundingSamples() {
        let base = Date()
        let samples = [
            makeHRSample(bpm: 120, at: base.addingTimeInterval(-4)),
            makeHRSample(bpm: 160, at: base.addingTimeInterval(1)),
        ]

        let result = ExportService.nearestHeartRate(for: base, in: samples, unit: bpmUnit)
        XCTAssertEqual(result, 160, "Should pick the sample 1s after over the one 4s before")
    }

    func testNearestHeartRateWithSingleSampleAtBoundary() {
        let base = Date()
        let samples = [
            makeHRSample(bpm: 100, at: base.addingTimeInterval(5)),
        ]

        let result = ExportService.nearestHeartRate(
            for: base,
            in: samples,
            unit: bpmUnit,
            maxInterval: 5.0
        )
        XCTAssertEqual(result, 100, "Exactly at maxInterval should still match")
    }
}
