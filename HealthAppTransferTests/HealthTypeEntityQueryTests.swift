import XCTest
@testable import HealthAppTransfer

final class HealthTypeEntityQueryTests: XCTestCase {

    // MARK: - HealthTypeAppEntity Init

    func testInitFromHealthDataTypePreservesFields() {
        let entity = HealthTypeAppEntity(from: .stepCount)
        XCTAssertEqual(entity.id, "stepCount")
        XCTAssertEqual(entity.displayName, HealthDataType.stepCount.displayName)
        XCTAssertEqual(entity.category, HealthDataType.stepCount.category.displayName)
    }

    // MARK: - healthDataType Roundtrip

    func testHealthDataTypeRoundtrip() {
        let entity = HealthTypeAppEntity(from: .heartRate)
        let roundtripped = entity.healthDataType
        XCTAssertEqual(roundtripped, .heartRate)
    }

    func testHealthDataTypeReturnsNilForInvalidID() {
        var entity = HealthTypeAppEntity(from: .stepCount)
        entity.id = "nonexistent_type"
        XCTAssertNil(entity.healthDataType)
    }

    // MARK: - ExportFormatAppEnum Mapping

    func testExportFormatMappingJsonFlat() {
        XCTAssertEqual(ExportFormatAppEnum.jsonFlat.exportFormat, .jsonV1)
    }

    func testExportFormatMappingJsonGrouped() {
        XCTAssertEqual(ExportFormatAppEnum.jsonGrouped.exportFormat, .jsonV2)
    }

    func testExportFormatMappingCSV() {
        XCTAssertEqual(ExportFormatAppEnum.csv.exportFormat, .csv)
    }

    // MARK: - DateRangeAppEnum.startDate

    func testDateRangeTodayReturnsStartOfToday() {
        let startDate = DateRangeAppEnum.today.startDate
        XCTAssertNotNil(startDate)
        let expected = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(startDate!.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1.0)
    }

    func testDateRangeAllTimeReturnsNil() {
        XCTAssertNil(DateRangeAppEnum.allTime.startDate)
    }

    func testDateRangeLastWeekReturnsDateInPast() {
        let startDate = DateRangeAppEnum.lastWeek.startDate
        XCTAssertNotNil(startDate)
        XCTAssertTrue(startDate! < Date())
    }

    // MARK: - HealthTypeEntityQuery

    func testEntitiesForValidIdentifiers() async throws {
        let query = HealthTypeEntityQuery()
        let results = try await query.entities(for: ["stepCount", "heartRate"])
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, "stepCount")
        XCTAssertEqual(results[1].id, "heartRate")
    }

    func testEntitiesForInvalidIdentifiersReturnsEmpty() async throws {
        let query = HealthTypeEntityQuery()
        let results = try await query.entities(for: ["nonexistent"])
        XCTAssertTrue(results.isEmpty)
    }

    func testEntitiesForMixedIdentifiersFiltersInvalid() async throws {
        let query = HealthTypeEntityQuery()
        let results = try await query.entities(for: ["stepCount", "invalid", "heartRate"])
        XCTAssertEqual(results.count, 2)
    }
}
