import XCTest
@testable import HealthAppTransfer

// MARK: - HealthSampleDTO Tests

final class HealthSampleDTOTests: XCTestCase {

    // MARK: - Codable Roundtrip

    func testQuantityDTOCodableRoundtrip() throws {
        let original = HealthSampleDTO(
            id: UUID(),
            type: .stepCount,
            startDate: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 1_000_060),
            sourceName: "Apple Watch",
            sourceBundleIdentifier: "com.apple.health",
            value: 10000,
            unit: "count",
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.type, .stepCount)
        XCTAssertEqual(decoded.value, 10000)
        XCTAssertEqual(decoded.unit, "count")
        XCTAssertEqual(decoded.sourceName, "Apple Watch")
    }

    func testCategoryDTOCodableRoundtrip() throws {
        let original = HealthSampleDTO(
            id: UUID(),
            type: .sleepAnalysis,
            startDate: Date(timeIntervalSince1970: 2_000_000),
            endDate: Date(timeIntervalSince1970: 2_030_000),
            sourceName: "Apple Watch",
            sourceBundleIdentifier: nil,
            value: nil,
            unit: nil,
            categoryValue: 3,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.type, .sleepAnalysis)
        XCTAssertEqual(decoded.categoryValue, 3)
        XCTAssertNil(decoded.value)
    }

    func testWorkoutDTOCodableRoundtrip() throws {
        let original = HealthSampleDTO(
            id: UUID(),
            type: .workout,
            startDate: Date(timeIntervalSince1970: 3_000_000),
            endDate: Date(timeIntervalSince1970: 3_001_800),
            sourceName: "Apple Watch",
            sourceBundleIdentifier: "com.apple.health",
            value: nil,
            unit: nil,
            categoryValue: nil,
            workoutActivityType: 37,
            workoutDuration: 1800,
            workoutTotalEnergyBurned: 350.5,
            workoutTotalDistance: 5000,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.type, .workout)
        XCTAssertEqual(decoded.workoutActivityType, 37)
        XCTAssertEqual(decoded.workoutDuration, 1800)
        XCTAssertEqual(decoded.workoutTotalEnergyBurned, 350.5)
        XCTAssertEqual(decoded.workoutTotalDistance, 5000)
    }

    func testCorrelationDTOCodableRoundtrip() throws {
        let original = HealthSampleDTO(
            id: UUID(),
            type: .bloodPressure,
            startDate: Date(timeIntervalSince1970: 4_000_000),
            endDate: Date(timeIntervalSince1970: 4_000_001),
            sourceName: "Omron",
            sourceBundleIdentifier: "com.omron.health",
            value: nil,
            unit: "mmHg",
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: ["systolic": 120, "diastolic": 80],
            characteristicValue: nil,
            metadataJSON: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.type, .bloodPressure)
        XCTAssertEqual(decoded.correlationValues?["systolic"], 120)
        XCTAssertEqual(decoded.correlationValues?["diastolic"], 80)
    }

    func testCharacteristicDTOCodableRoundtrip() throws {
        let original = HealthSampleDTO(
            id: UUID(),
            type: .biologicalSex,
            startDate: Date(),
            endDate: Date(),
            sourceName: "HealthKit",
            sourceBundleIdentifier: nil,
            value: nil,
            unit: nil,
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: "female",
            metadataJSON: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.type, .biologicalSex)
        XCTAssertEqual(decoded.characteristicValue, "female")
    }

    // MARK: - Identifiable

    func testDTOIsIdentifiable() {
        let id = UUID()
        let dto = HealthSampleDTO(
            id: id,
            type: .stepCount,
            startDate: Date(),
            endDate: Date(),
            sourceName: "Test",
            sourceBundleIdentifier: nil,
            value: 100,
            unit: "count",
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: nil
        )

        XCTAssertEqual(dto.id, id)
    }

    // MARK: - Metadata

    func testDTOWithMetadataJSON() throws {
        let dto = HealthSampleDTO(
            id: UUID(),
            type: .heartRate,
            startDate: Date(),
            endDate: Date(),
            sourceName: "Watch",
            sourceBundleIdentifier: nil,
            value: 72,
            unit: "count/min",
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: "{\"HKMotionContext\":1}"
        )

        let data = try JSONEncoder().encode(dto)
        let decoded = try JSONDecoder().decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.metadataJSON, "{\"HKMotionContext\":1}")
    }

    // MARK: - Nil Fields Preserved

    func testAllNilOptionalFieldsPreserved() throws {
        let dto = HealthSampleDTO(
            id: UUID(),
            type: .stepCount,
            startDate: Date(),
            endDate: Date(),
            sourceName: "Test",
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

        let data = try JSONEncoder().encode(dto)
        let decoded = try JSONDecoder().decode(HealthSampleDTO.self, from: data)

        XCTAssertNil(decoded.sourceBundleIdentifier)
        XCTAssertNil(decoded.value)
        XCTAssertNil(decoded.unit)
        XCTAssertNil(decoded.categoryValue)
        XCTAssertNil(decoded.workoutActivityType)
        XCTAssertNil(decoded.workoutDuration)
        XCTAssertNil(decoded.workoutTotalEnergyBurned)
        XCTAssertNil(decoded.workoutTotalDistance)
        XCTAssertNil(decoded.correlationValues)
        XCTAssertNil(decoded.characteristicValue)
        XCTAssertNil(decoded.metadataJSON)
    }
}

// MARK: - HealthDataBatch Tests

final class HealthDataBatchTests: XCTestCase {

    func testBatchCodableRoundtrip() throws {
        let sample = HealthSampleDTO(
            id: UUID(),
            type: .stepCount,
            startDate: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 1_000_060),
            sourceName: "Test",
            sourceBundleIdentifier: nil,
            value: 5000,
            unit: "count",
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: nil
        )

        let batch = HealthDataBatch(
            type: .stepCount,
            samples: [sample],
            totalCount: 100,
            offset: 0,
            limit: 50,
            hasMore: true
        )

        let data = try JSONEncoder().encode(batch)
        let decoded = try JSONDecoder().decode(HealthDataBatch.self, from: data)

        XCTAssertEqual(decoded.type, .stepCount)
        XCTAssertEqual(decoded.samples.count, 1)
        XCTAssertEqual(decoded.totalCount, 100)
        XCTAssertEqual(decoded.offset, 0)
        XCTAssertEqual(decoded.limit, 50)
        XCTAssertTrue(decoded.hasMore)
    }

    func testBatchWithNoMorePages() throws {
        let batch = HealthDataBatch(
            type: .heartRate,
            samples: [],
            totalCount: 10,
            offset: 10,
            limit: 50,
            hasMore: false
        )

        let data = try JSONEncoder().encode(batch)
        let decoded = try JSONDecoder().decode(HealthDataBatch.self, from: data)

        XCTAssertFalse(decoded.hasMore)
        XCTAssertEqual(decoded.type, .heartRate)
        XCTAssertTrue(decoded.samples.isEmpty)
    }
}

// MARK: - AggregatedSample Tests

final class AggregatedSampleTests: XCTestCase {

    func testAggregatedSampleCodableRoundtrip() throws {
        let sample = AggregatedSample(
            startDate: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 1_086_400),
            sum: 10000,
            average: nil,
            min: nil,
            max: nil,
            latest: 500,
            count: 1,
            unit: "count"
        )

        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(AggregatedSample.self, from: data)

        XCTAssertEqual(decoded.sum, 10000)
        XCTAssertNil(decoded.average)
        XCTAssertEqual(decoded.latest, 500)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.unit, "count")
    }

    func testAggregatedSampleWithDiscreteStats() throws {
        let sample = AggregatedSample(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            sum: nil,
            average: 72.5,
            min: 58.0,
            max: 95.0,
            latest: 68.0,
            count: 1,
            unit: "count/min"
        )

        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(AggregatedSample.self, from: data)

        XCTAssertNil(decoded.sum)
        XCTAssertEqual(decoded.average, 72.5)
        XCTAssertEqual(decoded.min, 58.0)
        XCTAssertEqual(decoded.max, 95.0)
        XCTAssertEqual(decoded.latest, 68.0)
    }
}

// MARK: - AggregationInterval Tests

final class AggregationIntervalTests: XCTestCase {

    func testAllIntervalsHaveDateComponents() {
        for interval in AggregationInterval.allCases {
            let components = interval.dateComponents
            // At least one component should be non-nil
            let hasValue = components.hour != nil ||
                           components.day != nil ||
                           components.month != nil ||
                           components.year != nil
            XCTAssertTrue(hasValue, "\(interval.rawValue) should have date components")
        }
    }

    func testIntervalCodableRoundtrip() throws {
        for interval in AggregationInterval.allCases {
            let data = try JSONEncoder().encode(interval)
            let decoded = try JSONDecoder().decode(AggregationInterval.self, from: data)
            XCTAssertEqual(decoded, interval)
        }
    }
}

// MARK: - AggregationOperation Tests

final class AggregationOperationTests: XCTestCase {

    func testAllOperationsCaseCount() {
        XCTAssertEqual(AggregationOperation.allCases.count, 6)
    }

    func testOperationCodableRoundtrip() throws {
        for op in AggregationOperation.allCases {
            let data = try JSONEncoder().encode(op)
            let decoded = try JSONDecoder().decode(AggregationOperation.self, from: data)
            XCTAssertEqual(decoded, op)
        }
    }
}

// MARK: - AggregationError Tests

final class AggregationErrorTests: XCTestCase {

    func testUnsupportedTypeErrorDescription() {
        let error = AggregationError.unsupportedType(.sleepAnalysis)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Sleep"))
    }

    func testUnsupportedTypeErrorForWorkout() {
        let error = AggregationError.unsupportedType(.workout)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Workouts"))
    }
}

// MARK: - ExportOptions Tests

final class ExportOptionsTests: XCTestCase {

    func testDefaultOptions() {
        let options = ExportOptions()
        XCTAssertNil(options.startDate)
        XCTAssertNil(options.endDate)
        XCTAssertFalse(options.prettyPrint)
        XCTAssertNil(options.deviceName)
        XCTAssertNil(options.deviceModel)
        XCTAssertNil(options.systemVersion)
        XCTAssertNil(options.appVersion)
    }

    func testCustomOptions() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = Date(timeIntervalSince1970: 2_000_000)
        let options = ExportOptions(
            startDate: start,
            endDate: end,
            prettyPrint: true,
            deviceName: "iPhone",
            deviceModel: "iPhone15,2",
            systemVersion: "17.5",
            appVersion: "1.0.0"
        )

        XCTAssertEqual(options.startDate, start)
        XCTAssertEqual(options.endDate, end)
        XCTAssertTrue(options.prettyPrint)
        XCTAssertEqual(options.deviceName, "iPhone")
        XCTAssertEqual(options.deviceModel, "iPhone15,2")
        XCTAssertEqual(options.systemVersion, "17.5")
        XCTAssertEqual(options.appVersion, "1.0.0")
    }
}
