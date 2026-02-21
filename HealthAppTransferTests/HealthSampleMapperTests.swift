import XCTest
import HealthKit
@testable import HealthAppTransfer

final class HealthSampleMapperTests: XCTestCase {

    // MARK: - Quantity Type Mapping

    func testMapQuantitySampleProducesCorrectDTO() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = start.addingTimeInterval(60)
        let sample = HKQuantitySample(
            type: HKQuantityType(.stepCount),
            quantity: HKQuantity(unit: .count(), doubleValue: 1234),
            start: start,
            end: end
        )

        let dto = HealthSampleMapper.map(sample, type: .stepCount)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .stepCount)
        XCTAssertEqual(dto?.value, 1234)
        XCTAssertEqual(dto?.unit, "count")
        XCTAssertEqual(dto?.startDate, start)
        XCTAssertEqual(dto?.endDate, end)
        XCTAssertNil(dto?.categoryValue)
        XCTAssertNil(dto?.correlationValues)
        XCTAssertNil(dto?.characteristicValue)
        XCTAssertNil(dto?.workoutActivityType)
    }

    func testMapQuantitySampleReturnsNilForCategoryType() {
        let sample = HKQuantitySample(
            type: HKQuantityType(.heartRate),
            quantity: HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: 72),
            start: Date(),
            end: Date()
        )

        let dto = HealthSampleMapper.map(sample, type: .sleepAnalysis)
        XCTAssertNil(dto, "Quantity sample should not map to a category type")
    }

    // MARK: - Category Type Mapping

    func testMapCategorySampleProducesCorrectDTO() {
        let start = Date(timeIntervalSince1970: 2_000_000)
        let end = start.addingTimeInterval(3600)
        let sample = HKCategorySample(
            type: HKCategoryType(.sleepAnalysis),
            value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            start: start,
            end: end
        )

        let dto = HealthSampleMapper.map(sample, type: .sleepAnalysis)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .sleepAnalysis)
        XCTAssertEqual(dto?.categoryValue, HKCategoryValueSleepAnalysis.asleepCore.rawValue)
        XCTAssertNil(dto?.value)
        XCTAssertNil(dto?.unit)
        XCTAssertNil(dto?.correlationValues)
        XCTAssertNil(dto?.characteristicValue)
    }

    func testMapCategorySampleMapsSymptomTypes() {
        let sample = HKCategorySample(
            type: HKCategoryType(.headache),
            value: 2, // moderate
            start: Date(),
            end: Date()
        )

        let dto = HealthSampleMapper.map(sample, type: .headache)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .headache)
        XCTAssertEqual(dto?.categoryValue, 2)
    }

    func testMapCategorySampleMapsReproductiveHealthTypes() {
        let sample = HKCategorySample(
            type: HKCategoryType(.menstrualFlow),
            value: HKCategoryValueMenstrualFlow.medium.rawValue,
            start: Date(),
            end: Date(),
            metadata: [HKMetadataKeyMenstrualCycleStart: true]
        )

        let dto = HealthSampleMapper.map(sample, type: .menstrualFlow)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .menstrualFlow)
        XCTAssertEqual(dto?.categoryValue, HKCategoryValueMenstrualFlow.medium.rawValue)
    }

    func testMapCategorySampleMapsHeartEventTypes() {
        let sample = HKCategorySample(
            type: HKCategoryType(.highHeartRateEvent),
            value: 0,
            start: Date(),
            end: Date()
        )

        let dto = HealthSampleMapper.map(sample, type: .highHeartRateEvent)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .highHeartRateEvent)
        XCTAssertEqual(dto?.categoryValue, 0)
    }

    // MARK: - Correlation Type Mapping

    func testMapBloodPressureCorrelationExtractsBothValues() {
        let start = Date(timeIntervalSince1970: 3_000_000)
        let end = start.addingTimeInterval(1)

        let systolicSample = HKQuantitySample(
            type: HKQuantityType(.bloodPressureSystolic),
            quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 120),
            start: start,
            end: end
        )
        let diastolicSample = HKQuantitySample(
            type: HKQuantityType(.bloodPressureDiastolic),
            quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 80),
            start: start,
            end: end
        )

        let correlation = HKCorrelation(
            type: HKCorrelationType(.bloodPressure),
            start: start,
            end: end,
            objects: [systolicSample, diastolicSample]
        )

        let dto = HealthSampleMapper.map(correlation, type: .bloodPressure)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .bloodPressure)
        XCTAssertEqual(dto?.unit, "mmHg")
        XCTAssertEqual(dto?.correlationValues?["systolic"], 120)
        XCTAssertEqual(dto?.correlationValues?["diastolic"], 80)
        XCTAssertNil(dto?.value)
        XCTAssertNil(dto?.characteristicValue)
    }

    func testMapFoodCorrelationExtractsNutrientValues() {
        let start = Date(timeIntervalSince1970: 4_000_000)
        let end = start.addingTimeInterval(1)

        let energySample = HKQuantitySample(
            type: HKQuantityType(.dietaryEnergyConsumed),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: 500),
            start: start,
            end: end
        )
        let proteinSample = HKQuantitySample(
            type: HKQuantityType(.dietaryProtein),
            quantity: HKQuantity(unit: .gram(), doubleValue: 25),
            start: start,
            end: end
        )

        let correlation = HKCorrelation(
            type: HKCorrelationType(.food),
            start: start,
            end: end,
            objects: [energySample, proteinSample]
        )

        let dto = HealthSampleMapper.map(correlation, type: .food)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .food)
        XCTAssertNil(dto?.unit)
        XCTAssertEqual(dto?.correlationValues?["dietaryEnergyConsumed"], 500)
        XCTAssertEqual(dto?.correlationValues?["dietaryProtein"], 25)
        XCTAssertNil(dto?.value)
    }

    func testMapFoodCorrelationWithSingleNutrient() {
        let start = Date(timeIntervalSince1970: 4_500_000)
        let end = start.addingTimeInterval(1)

        let carbsSample = HKQuantitySample(
            type: HKQuantityType(.dietaryCarbohydrates),
            quantity: HKQuantity(unit: .gram(), doubleValue: 45),
            start: start,
            end: end
        )

        let correlation = HKCorrelation(
            type: HKCorrelationType(.food),
            start: start,
            end: end,
            objects: [carbsSample]
        )

        let dto = HealthSampleMapper.map(correlation, type: .food)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.correlationValues?["dietaryCarbohydrates"], 45)
        XCTAssertEqual(dto?.correlationValues?.count, 1)
    }

    // MARK: - Characteristic Type Mapping

    func testMapCharacteristicProducesCorrectDTO() {
        let dto = HealthSampleMapper.mapCharacteristic(.biologicalSex, stringValue: "female")

        XCTAssertEqual(dto.type, .biologicalSex)
        XCTAssertEqual(dto.characteristicValue, "female")
        XCTAssertEqual(dto.sourceName, "HealthKit")
        XCTAssertNil(dto.value)
        XCTAssertNil(dto.unit)
        XCTAssertNil(dto.categoryValue)
        XCTAssertNil(dto.correlationValues)
        XCTAssertNil(dto.workoutActivityType)
    }

    func testMapCharacteristicBloodType() {
        let dto = HealthSampleMapper.mapCharacteristic(.bloodType, stringValue: "O+")
        XCTAssertEqual(dto.characteristicValue, "O+")
        XCTAssertEqual(dto.type, .bloodType)
    }

    func testMapCharacteristicDateOfBirth() {
        let dateString = "1990-01-15T00:00:00Z"
        let dto = HealthSampleMapper.mapCharacteristic(.dateOfBirth, stringValue: dateString)
        XCTAssertEqual(dto.characteristicValue, dateString)
        XCTAssertEqual(dto.type, .dateOfBirth)
    }

    func testMapCharacteristicFitzpatrickSkinType() {
        let dto = HealthSampleMapper.mapCharacteristic(.fitzpatrickSkinType, stringValue: "III")
        XCTAssertEqual(dto.characteristicValue, "III")
    }

    func testMapCharacteristicWheelchairUse() {
        let dto = HealthSampleMapper.mapCharacteristic(.wheelchairUse, stringValue: "no")
        XCTAssertEqual(dto.characteristicValue, "no")
    }

    func testMapCharacteristicActivityMoveMode() {
        let dto = HealthSampleMapper.mapCharacteristic(.activityMoveMode, stringValue: "activeEnergy")
        XCTAssertEqual(dto.characteristicValue, "activeEnergy")
    }

    // MARK: - Workout Type Mapping

    @available(iOS, deprecated: 17.0)
    func testMapWorkoutProducesCorrectDTO() {
        let start = Date(timeIntervalSince1970: 5_000_000)
        let end = start.addingTimeInterval(1800)
        let workout = makeLegacyWorkout(activityType: .running, start: start, end: end)

        let dto = HealthSampleMapper.map(workout, type: .workout)

        XCTAssertNotNil(dto)
        XCTAssertEqual(dto?.type, .workout)
        XCTAssertEqual(dto?.workoutActivityType, HKWorkoutActivityType.running.rawValue)
        XCTAssertEqual(dto?.workoutDuration, 1800)
        XCTAssertNil(dto?.value)
        XCTAssertNil(dto?.correlationValues)
        XCTAssertNil(dto?.characteristicValue)
    }

    // MARK: - Batch Mapping

    func testMapArrayFiltersInvalidSamples() {
        let validSample = HKQuantitySample(
            type: HKQuantityType(.stepCount),
            quantity: HKQuantity(unit: .count(), doubleValue: 100),
            start: Date(),
            end: Date()
        )

        let results = HealthSampleMapper.map([validSample], type: .stepCount)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.value, 100)
    }

    // MARK: - Metadata Encoding

    func testMapPreservesMetadata() {
        let sample = HKQuantitySample(
            type: HKQuantityType(.heartRate),
            quantity: HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: 72),
            start: Date(),
            end: Date(),
            metadata: ["HKMotionContext": 1]
        )

        let dto = HealthSampleMapper.map(sample, type: .heartRate)

        XCTAssertNotNil(dto?.metadataJSON)
    }

    func testMapHandlesNilMetadata() {
        let sample = HKQuantitySample(
            type: HKQuantityType(.stepCount),
            quantity: HKQuantity(unit: .count(), doubleValue: 50),
            start: Date(),
            end: Date()
        )

        let dto = HealthSampleMapper.map(sample, type: .stepCount)
        XCTAssertNil(dto?.metadataJSON)
    }

    // MARK: - DTO Codable Roundtrip

    func testDTOWithCorrelationValuesEncodesAndDecodes() throws {
        let dto = HealthSampleDTO(
            id: UUID(),
            type: .bloodPressure,
            startDate: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 1_000_001),
            sourceName: "TestApp",
            sourceBundleIdentifier: "com.test",
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

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let decoded = try JSONDecoder().decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.correlationValues?["systolic"], 120)
        XCTAssertEqual(decoded.correlationValues?["diastolic"], 80)
        XCTAssertEqual(decoded.type, .bloodPressure)
    }

    func testDTOWithCharacteristicValueEncodesAndDecodes() throws {
        let dto = HealthSampleDTO(
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

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let decoded = try JSONDecoder().decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.characteristicValue, "female")
        XCTAssertEqual(decoded.type, .biologicalSex)
    }

    // MARK: - Helpers

    @available(iOS, deprecated: 17.0)
    private func makeLegacyWorkout(activityType: HKWorkoutActivityType, start: Date, end: Date) -> HKWorkout {
        HKWorkout(activityType: activityType, start: start, end: end)
    }
}
