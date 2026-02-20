import XCTest
import CloudKit
@testable import HealthAppTransfer

final class CloudKitRecordMapperTests: XCTestCase {

    // MARK: - Helpers

    private func makeDTO(
        id: UUID = UUID(),
        type: HealthDataType = .stepCount,
        startDate: Date = Date(timeIntervalSince1970: 1_000_000),
        endDate: Date = Date(timeIntervalSince1970: 1_000_060),
        sourceName: String = "TestSource",
        sourceBundleIdentifier: String? = "com.test.app",
        value: Double? = 5000,
        unit: String? = "count",
        categoryValue: Int? = nil,
        workoutActivityType: UInt? = nil,
        workoutDuration: TimeInterval? = nil,
        workoutTotalEnergyBurned: Double? = nil,
        workoutTotalDistance: Double? = nil,
        correlationValues: [String: Double]? = nil,
        characteristicValue: String? = nil,
        metadataJSON: String? = nil
    ) -> HealthSampleDTO {
        HealthSampleDTO(
            id: id,
            type: type,
            startDate: startDate,
            endDate: endDate,
            sourceName: sourceName,
            sourceBundleIdentifier: sourceBundleIdentifier,
            value: value,
            unit: unit,
            categoryValue: categoryValue,
            workoutActivityType: workoutActivityType,
            workoutDuration: workoutDuration,
            workoutTotalEnergyBurned: workoutTotalEnergyBurned,
            workoutTotalDistance: workoutTotalDistance,
            correlationValues: correlationValues,
            characteristicValue: characteristicValue,
            metadataJSON: metadataJSON
        )
    }

    // MARK: - Constants

    func testRecordType() {
        XCTAssertEqual(CloudKitRecordMapper.recordType, "HealthSample")
    }

    func testZoneName() {
        XCTAssertEqual(CloudKitRecordMapper.zoneName, "HealthData")
    }

    func testZoneID() {
        let zoneID = CloudKitRecordMapper.zoneID
        XCTAssertEqual(zoneID.zoneName, "HealthData")
    }

    // MARK: - DTO → CKRecord (Quantity)

    func testQuantityDTOToRecord() {
        let id = UUID()
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = Date(timeIntervalSince1970: 1_000_060)

        let dto = makeDTO(
            id: id,
            type: .stepCount,
            startDate: start,
            endDate: end,
            value: 10000,
            unit: "count"
        )

        let record = CloudKitRecordMapper.record(from: dto)

        XCTAssertEqual(record.recordID.recordName, id.uuidString)
        XCTAssertEqual(record.recordType, "HealthSample")
        XCTAssertEqual(record["typeRawValue"] as? String, "stepCount")
        XCTAssertEqual(record["startDate"] as? Date, start)
        XCTAssertEqual(record["endDate"] as? Date, end)
        XCTAssertEqual(record["sourceName"] as? String, "TestSource")
        XCTAssertEqual(record["sourceBundleIdentifier"] as? String, "com.test.app")
        XCTAssertEqual((record["value"] as? NSNumber)?.doubleValue, 10000)
        XCTAssertEqual(record["unit"] as? String, "count")
        XCTAssertNil(record["categoryValue"])
        XCTAssertNil(record["workoutActivityType"])
    }

    // MARK: - DTO → CKRecord (Category)

    func testCategoryDTOToRecord() {
        let dto = makeDTO(
            type: .sleepAnalysis,
            value: nil,
            unit: nil,
            categoryValue: 3
        )

        let record = CloudKitRecordMapper.record(from: dto)

        XCTAssertEqual(record["typeRawValue"] as? String, "sleepAnalysis")
        XCTAssertEqual((record["categoryValue"] as? NSNumber)?.intValue, 3)
        XCTAssertNil(record["value"])
    }

    // MARK: - DTO → CKRecord (Workout)

    func testWorkoutDTOToRecord() {
        let dto = makeDTO(
            type: .workout,
            value: nil,
            unit: nil,
            workoutActivityType: 37,
            workoutDuration: 1800,
            workoutTotalEnergyBurned: 350.5,
            workoutTotalDistance: 5000
        )

        let record = CloudKitRecordMapper.record(from: dto)

        XCTAssertEqual(record["typeRawValue"] as? String, "workout")
        XCTAssertEqual((record["workoutActivityType"] as? NSNumber)?.int64Value, 37)
        XCTAssertEqual((record["workoutDuration"] as? NSNumber)?.doubleValue, 1800)
        XCTAssertEqual((record["workoutTotalEnergyBurned"] as? NSNumber)?.doubleValue, 350.5)
        XCTAssertEqual((record["workoutTotalDistance"] as? NSNumber)?.doubleValue, 5000)
    }

    // MARK: - DTO → CKRecord (Correlation)

    func testCorrelationDTOToRecord() {
        let dto = makeDTO(
            type: .bloodPressure,
            value: nil,
            unit: "mmHg",
            correlationValues: ["systolic": 120, "diastolic": 80]
        )

        let record = CloudKitRecordMapper.record(from: dto)

        XCTAssertEqual(record["typeRawValue"] as? String, "bloodPressure")
        XCTAssertEqual(record["unit"] as? String, "mmHg")

        // Correlation values are encoded as JSON string
        let json = record["correlationValuesJSON"] as? String
        XCTAssertNotNil(json)
        if let json, let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            XCTAssertEqual(decoded["systolic"], 120)
            XCTAssertEqual(decoded["diastolic"], 80)
        }
    }

    // MARK: - DTO → CKRecord (Characteristic)

    func testCharacteristicDTOToRecord() {
        let dto = makeDTO(
            type: .biologicalSex,
            value: nil,
            unit: nil,
            characteristicValue: "female"
        )

        let record = CloudKitRecordMapper.record(from: dto)

        XCTAssertEqual(record["typeRawValue"] as? String, "biologicalSex")
        XCTAssertEqual(record["characteristicValue"] as? String, "female")
    }

    // MARK: - DTO → CKRecord (Metadata)

    func testMetadataJSONPreserved() {
        let dto = makeDTO(metadataJSON: "{\"key\":\"value\"}")

        let record = CloudKitRecordMapper.record(from: dto)

        XCTAssertEqual(record["metadataJSON"] as? String, "{\"key\":\"value\"}")
    }

    func testNilMetadataJSONPreserved() {
        let dto = makeDTO(metadataJSON: nil)

        let record = CloudKitRecordMapper.record(from: dto)

        XCTAssertNil(record["metadataJSON"])
    }

    // MARK: - CKRecord → DTO

    func testRecordToQuantityDTO() {
        let id = UUID()
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = Date(timeIntervalSince1970: 1_000_060)

        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "stepCount" as NSString
        record["startDate"] = start as NSDate
        record["endDate"] = end as NSDate
        record["sourceName"] = "TestSource" as NSString
        record["sourceBundleIdentifier"] = "com.test.app" as NSString
        record["value"] = 10000 as NSNumber
        record["unit"] = "count" as NSString

        let dto = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.id, id)
        XCTAssertEqual(dto?.type, .stepCount)
        XCTAssertEqual(dto?.startDate, start)
        XCTAssertEqual(dto?.endDate, end)
        XCTAssertEqual(dto?.sourceName, "TestSource")
        XCTAssertEqual(dto?.sourceBundleIdentifier, "com.test.app")
        XCTAssertEqual(dto?.value, 10000)
        XCTAssertEqual(dto?.unit, "count")
    }

    func testRecordToCategoryDTO() {
        let id = UUID()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "sleepAnalysis" as NSString
        record["startDate"] = Date() as NSDate
        record["endDate"] = Date() as NSDate
        record["sourceName"] = "TestSource" as NSString
        record["categoryValue"] = 3 as NSNumber

        let dto = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .sleepAnalysis)
        XCTAssertEqual(dto?.categoryValue, 3)
        XCTAssertNil(dto?.value)
    }

    func testRecordToWorkoutDTO() {
        let id = UUID()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "workout" as NSString
        record["startDate"] = Date() as NSDate
        record["endDate"] = Date() as NSDate
        record["sourceName"] = "TestSource" as NSString
        record["workoutActivityType"] = Int64(37) as NSNumber
        record["workoutDuration"] = 1800.0 as NSNumber
        record["workoutTotalEnergyBurned"] = 350.5 as NSNumber
        record["workoutTotalDistance"] = 5000.0 as NSNumber

        let dto = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .workout)
        XCTAssertEqual(dto?.workoutActivityType, 37)
        XCTAssertEqual(dto?.workoutDuration, 1800)
        XCTAssertEqual(dto?.workoutTotalEnergyBurned, 350.5)
        XCTAssertEqual(dto?.workoutTotalDistance, 5000)
    }

    func testRecordToCorrelationDTO() {
        let id = UUID()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "bloodPressure" as NSString
        record["startDate"] = Date() as NSDate
        record["endDate"] = Date() as NSDate
        record["sourceName"] = "TestSource" as NSString
        record["unit"] = "mmHg" as NSString

        let correlationJSON = try! JSONEncoder().encode(["systolic": 120.0, "diastolic": 80.0])
        record["correlationValuesJSON"] = String(data: correlationJSON, encoding: .utf8)! as NSString

        let dto = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .bloodPressure)
        XCTAssertEqual(dto?.correlationValues?["systolic"], 120)
        XCTAssertEqual(dto?.correlationValues?["diastolic"], 80)
        XCTAssertEqual(dto?.unit, "mmHg")
    }

    func testRecordToCharacteristicDTO() {
        let id = UUID()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "biologicalSex" as NSString
        record["startDate"] = Date() as NSDate
        record["endDate"] = Date() as NSDate
        record["sourceName"] = "HealthKit" as NSString
        record["characteristicValue"] = "female" as NSString

        let dto = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .biologicalSex)
        XCTAssertEqual(dto?.characteristicValue, "female")
    }

    // MARK: - Invalid Records

    func testRecordWithMissingTypeReturnsNil() {
        let id = UUID()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["startDate"] = Date() as NSDate
        record["endDate"] = Date() as NSDate
        record["sourceName"] = "Test" as NSString
        // Missing typeRawValue

        XCTAssertNil(CloudKitRecordMapper.dto(from: record))
    }

    func testRecordWithInvalidTypeReturnsNil() {
        let id = UUID()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "nonExistentType" as NSString
        record["startDate"] = Date() as NSDate
        record["endDate"] = Date() as NSDate
        record["sourceName"] = "Test" as NSString

        XCTAssertNil(CloudKitRecordMapper.dto(from: record))
    }

    func testRecordWithMissingStartDateReturnsNil() {
        let id = UUID()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "stepCount" as NSString
        record["endDate"] = Date() as NSDate
        record["sourceName"] = "Test" as NSString
        // Missing startDate

        XCTAssertNil(CloudKitRecordMapper.dto(from: record))
    }

    func testRecordWithMissingSourceNameReturnsNil() {
        let id = UUID()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "stepCount" as NSString
        record["startDate"] = Date() as NSDate
        record["endDate"] = Date() as NSDate
        // Missing sourceName

        XCTAssertNil(CloudKitRecordMapper.dto(from: record))
    }

    func testRecordWithInvalidUUIDReturnsNil() {
        let recordID = CKRecord.ID(recordName: "not-a-uuid", zoneID: CloudKitRecordMapper.zoneID)
        let record = CKRecord(recordType: "HealthSample", recordID: recordID)
        record["typeRawValue"] = "stepCount" as NSString
        record["startDate"] = Date() as NSDate
        record["endDate"] = Date() as NSDate
        record["sourceName"] = "Test" as NSString

        XCTAssertNil(CloudKitRecordMapper.dto(from: record))
    }

    // MARK: - Roundtrip Tests

    func testQuantityDTORoundtrip() {
        let original = makeDTO(
            type: .heartRate,
            value: 72.5,
            unit: "count/min"
        )

        let record = CloudKitRecordMapper.record(from: original)
        let decoded = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.id, original.id)
        XCTAssertEqual(decoded?.type, original.type)
        XCTAssertEqual(decoded?.value, original.value)
        XCTAssertEqual(decoded?.unit, original.unit)
        XCTAssertEqual(decoded?.sourceName, original.sourceName)
        XCTAssertEqual(decoded?.sourceBundleIdentifier, original.sourceBundleIdentifier)
    }

    func testCategoryDTORoundtrip() {
        let original = makeDTO(
            type: .sleepAnalysis,
            value: nil,
            unit: nil,
            categoryValue: 2
        )

        let record = CloudKitRecordMapper.record(from: original)
        let decoded = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.id, original.id)
        XCTAssertEqual(decoded?.type, original.type)
        XCTAssertEqual(decoded?.categoryValue, original.categoryValue)
        XCTAssertNil(decoded?.value)
    }

    func testWorkoutDTORoundtrip() {
        let original = makeDTO(
            type: .workout,
            value: nil,
            unit: nil,
            workoutActivityType: 37,
            workoutDuration: 3600,
            workoutTotalEnergyBurned: 500,
            workoutTotalDistance: 10000
        )

        let record = CloudKitRecordMapper.record(from: original)
        let decoded = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.id, original.id)
        XCTAssertEqual(decoded?.type, original.type)
        XCTAssertEqual(decoded?.workoutActivityType, original.workoutActivityType)
        XCTAssertEqual(decoded?.workoutDuration, original.workoutDuration)
        XCTAssertEqual(decoded?.workoutTotalEnergyBurned, original.workoutTotalEnergyBurned)
        XCTAssertEqual(decoded?.workoutTotalDistance, original.workoutTotalDistance)
    }

    func testCorrelationDTORoundtrip() {
        let original = makeDTO(
            type: .bloodPressure,
            value: nil,
            unit: "mmHg",
            correlationValues: ["systolic": 120, "diastolic": 80]
        )

        let record = CloudKitRecordMapper.record(from: original)
        let decoded = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.id, original.id)
        XCTAssertEqual(decoded?.type, original.type)
        XCTAssertEqual(decoded?.correlationValues?["systolic"], 120)
        XCTAssertEqual(decoded?.correlationValues?["diastolic"], 80)
    }

    func testCharacteristicDTORoundtrip() {
        let original = makeDTO(
            type: .biologicalSex,
            value: nil,
            unit: nil,
            characteristicValue: "male"
        )

        let record = CloudKitRecordMapper.record(from: original)
        let decoded = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.id, original.id)
        XCTAssertEqual(decoded?.type, original.type)
        XCTAssertEqual(decoded?.characteristicValue, "male")
    }

    func testMetadataJSONRoundtrip() {
        let original = makeDTO(metadataJSON: "{\"HKMotionContext\":1}")

        let record = CloudKitRecordMapper.record(from: original)
        let decoded = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.metadataJSON, original.metadataJSON)
    }

    // MARK: - Nil Optional Fields

    func testNilOptionalFieldsRoundtrip() {
        let original = makeDTO(
            sourceBundleIdentifier: nil,
            value: nil,
            unit: nil,
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: nil
        )

        let record = CloudKitRecordMapper.record(from: original)
        let decoded = CloudKitRecordMapper.dto(from: record)

        XCTAssertNotNil(decoded)
        XCTAssertNil(decoded?.sourceBundleIdentifier)
        XCTAssertNil(decoded?.value)
        XCTAssertNil(decoded?.unit)
        XCTAssertNil(decoded?.categoryValue)
        XCTAssertNil(decoded?.workoutActivityType)
        XCTAssertNil(decoded?.workoutDuration)
        XCTAssertNil(decoded?.workoutTotalEnergyBurned)
        XCTAssertNil(decoded?.workoutTotalDistance)
        XCTAssertNil(decoded?.correlationValues)
        XCTAssertNil(decoded?.characteristicValue)
        XCTAssertNil(decoded?.metadataJSON)
    }

    // MARK: - Record Zone

    func testRecordUsesCorrectZone() {
        let dto = makeDTO()
        let record = CloudKitRecordMapper.record(from: dto)

        XCTAssertEqual(record.recordID.zoneID.zoneName, "HealthData")
    }

    // MARK: - Multiple Types Roundtrip

    func testMultipleTypesRoundtrip() {
        let types: [(HealthDataType, Double?, String?, Int?)] = [
            (.stepCount, 10000, "count", nil),
            (.heartRate, 72, "count/min", nil),
            (.bodyMass, 75.5, "kg", nil),
            (.sleepAnalysis, nil, nil, 3),
            (.mindfulSession, nil, nil, 0),
        ]

        for (type, value, unit, categoryValue) in types {
            let original = makeDTO(type: type, value: value, unit: unit, categoryValue: categoryValue)
            let record = CloudKitRecordMapper.record(from: original)
            let decoded = CloudKitRecordMapper.dto(from: record)

            XCTAssertNotNil(decoded, "Roundtrip failed for \(type.rawValue)")
            XCTAssertEqual(decoded?.type, type, "Type mismatch for \(type.rawValue)")
            XCTAssertEqual(decoded?.value, value, "Value mismatch for \(type.rawValue)")
            XCTAssertEqual(decoded?.unit, unit, "Unit mismatch for \(type.rawValue)")
            XCTAssertEqual(decoded?.categoryValue, categoryValue, "CategoryValue mismatch for \(type.rawValue)")
        }
    }
}
