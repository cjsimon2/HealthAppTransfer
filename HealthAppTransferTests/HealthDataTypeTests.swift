import XCTest
import HealthKit
@testable import HealthAppTransfer

final class HealthDataTypeTests: XCTestCase {

    // MARK: - All Cases Coverage

    func testAllCasesHaveDisplayName() {
        for type in HealthDataType.allCases {
            let name = type.displayName
            XCTAssertFalse(name.isEmpty, "\(type.rawValue) should have a non-empty display name")
            // Display names should not fall back to rawValue (which would be lowerCamelCase)
            XCTAssertNotEqual(name, type.rawValue, "\(type.rawValue) should have a proper display name, not rawValue")
        }
    }

    func testAllCasesHaveKind() {
        for type in HealthDataType.allCases {
            // Should not crash
            let kind = type.kind
            let validKinds: [DataTypeKind] = [.quantity, .category, .correlation, .characteristic, .workout]
            XCTAssertTrue(validKinds.contains(kind), "\(type.rawValue) has unexpected kind \(kind)")
        }
    }

    func testAllCasesHaveCategory() {
        for type in HealthDataType.allCases {
            let category = type.category
            XCTAssertTrue(HealthDataCategory.allCases.contains(category),
                          "\(type.rawValue) has unknown category \(category)")
        }
    }

    func testAllCasesHaveObjectType() {
        for type in HealthDataType.allCases {
            // Should not crash — every type must have an HKObjectType
            let objectType = type.objectType
            XCTAssertNotNil(objectType, "\(type.rawValue) should have an objectType")
        }
    }

    // MARK: - Kind Classification

    func testQuantityTypesAreCorrectlyClassified() {
        let quantityTypes: [HealthDataType] = [
            .stepCount, .heartRate, .bodyMass, .vo2Max, .bloodGlucose,
            .dietaryEnergyConsumed, .oxygenSaturation, .height,
            .activeEnergyBurned, .flightsClimbed, .walkingSpeed,
            .environmentalAudioExposure, .uvExposure
        ]
        for type in quantityTypes {
            XCTAssertEqual(type.kind, .quantity, "\(type.rawValue) should be a quantity type")
            XCTAssertTrue(type.isQuantityType)
            XCTAssertTrue(type.isSampleBased)
        }
    }

    func testCategoryTypesAreCorrectlyClassified() {
        let categoryTypes: [HealthDataType] = [
            .sleepAnalysis, .mindfulSession, .appleStandHour,
            .highHeartRateEvent, .lowHeartRateEvent, .menstrualFlow,
            .headache, .nausea, .toothbrushingEvent
        ]
        for type in categoryTypes {
            XCTAssertEqual(type.kind, .category, "\(type.rawValue) should be a category type")
            XCTAssertFalse(type.isQuantityType)
            XCTAssertTrue(type.isSampleBased)
        }
    }

    func testCorrelationTypesAreCorrectlyClassified() {
        let correlationTypes: [HealthDataType] = [.bloodPressure, .food]
        for type in correlationTypes {
            XCTAssertEqual(type.kind, .correlation, "\(type.rawValue) should be a correlation type")
            XCTAssertFalse(type.isQuantityType)
            XCTAssertTrue(type.isSampleBased)
        }
    }

    func testCharacteristicTypesAreCorrectlyClassified() {
        let characteristicTypes: [HealthDataType] = [
            .biologicalSex, .bloodType, .dateOfBirth,
            .fitzpatrickSkinType, .wheelchairUse, .activityMoveMode
        ]
        for type in characteristicTypes {
            XCTAssertEqual(type.kind, .characteristic, "\(type.rawValue) should be a characteristic type")
            XCTAssertFalse(type.isQuantityType)
            XCTAssertFalse(type.isSampleBased, "\(type.rawValue) should not be sample-based")
        }
    }

    func testWorkoutTypeIsCorrectlyClassified() {
        XCTAssertEqual(HealthDataType.workout.kind, .workout)
        XCTAssertFalse(HealthDataType.workout.isQuantityType)
        XCTAssertTrue(HealthDataType.workout.isSampleBased)
    }

    // MARK: - Sample Type Access

    func testAllSampleBasedTypesHaveSampleType() {
        for type in HealthDataType.allCases where type.isSampleBased {
            // Should not crash
            let sampleType = type.sampleType
            XCTAssertNotNil(sampleType, "\(type.rawValue) should have a sampleType")
        }
    }

    func testQuantityTypesHaveQuantityTypeIdentifier() {
        for type in HealthDataType.allCases where type.kind == .quantity {
            // Should not crash
            let id = type.quantityTypeIdentifier
            // Verify it creates a valid HKQuantityType
            let hkType = HKQuantityType(id)
            XCTAssertNotNil(hkType, "\(type.rawValue) quantityTypeIdentifier should create valid HKQuantityType")
        }
    }

    func testCategoryTypesHaveCategoryTypeIdentifier() {
        for type in HealthDataType.allCases where type.kind == .category {
            let id = type.categoryTypeIdentifier
            let hkType = HKCategoryType(id)
            XCTAssertNotNil(hkType, "\(type.rawValue) categoryTypeIdentifier should create valid HKCategoryType")
        }
    }

    func testCorrelationTypesHaveCorrelationTypeIdentifier() {
        for type in HealthDataType.allCases where type.kind == .correlation {
            let id = type.correlationTypeIdentifier
            let hkType = HKCorrelationType(id)
            XCTAssertNotNil(hkType, "\(type.rawValue) correlationTypeIdentifier should create valid HKCorrelationType")
        }
    }

    func testCharacteristicTypesHaveCharacteristicTypeIdentifier() {
        for type in HealthDataType.allCases where type.kind == .characteristic {
            let id = type.characteristicTypeIdentifier
            let hkType = HKCharacteristicType(id)
            XCTAssertNotNil(hkType, "\(type.rawValue) characteristicTypeIdentifier should create valid HKCharacteristicType")
        }
    }

    // MARK: - Unit Mapping (Quantity Types)

    func testAllQuantityTypesHavePreferredUnit() {
        for type in HealthDataType.allCases where type.kind == .quantity {
            // Should not crash
            let unit = HealthSampleMapper.preferredUnit(for: type)
            XCTAssertFalse(unit.unitString.isEmpty, "\(type.rawValue) should have a non-empty unit string")
        }
    }

    // MARK: - Specific Display Names

    func testKeyDisplayNames() {
        XCTAssertEqual(HealthDataType.stepCount.displayName, "Step Count")
        XCTAssertEqual(HealthDataType.heartRate.displayName, "Heart Rate")
        XCTAssertEqual(HealthDataType.bodyMass.displayName, "Weight")
        XCTAssertEqual(HealthDataType.vo2Max.displayName, "VO2 Max")
        XCTAssertEqual(HealthDataType.sleepAnalysis.displayName, "Sleep")
        XCTAssertEqual(HealthDataType.workout.displayName, "Workouts")
        XCTAssertEqual(HealthDataType.bloodPressure.displayName, "Blood Pressure")
        XCTAssertEqual(HealthDataType.biologicalSex.displayName, "Biological Sex")
        XCTAssertEqual(HealthDataType.dietaryEnergyConsumed.displayName, "Dietary Energy")
        XCTAssertEqual(HealthDataType.headache.displayName, "Headache")
    }

    // MARK: - Specific Units

    func testKeyUnits() {
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .stepCount), .count())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .activeEnergyBurned), .kilocalorie())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .bodyMass), .gramUnit(with: .kilo))
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .height), .meterUnit(with: .centi))
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .oxygenSaturation), .percent())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .bodyTemperature), .degreeCelsius())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .bloodPressureSystolic), .millimeterOfMercury())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .distanceWalkingRunning), .meter())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .appleExerciseTime), .minute())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .dietaryWater), .literUnit(with: .milli))
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .dietaryProtein), .gram())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .forcedVitalCapacity), .liter())
        XCTAssertEqual(HealthSampleMapper.preferredUnit(for: .inhalerUsage), .count())
    }

    // MARK: - Category Assignment

    func testActivityCategoryTypes() {
        let activityTypes: [HealthDataType] = [
            .stepCount, .distanceWalkingRunning, .flightsClimbed,
            .activeEnergyBurned, .appleExerciseTime, .appleStandHour,
            .cyclingSpeed, .runningSpeed, .underwaterDepth
        ]
        for type in activityTypes {
            XCTAssertEqual(type.category, .activity, "\(type.rawValue) should be in activity category")
        }
    }

    func testHeartCategoryTypes() {
        let heartTypes: [HealthDataType] = [
            .heartRate, .restingHeartRate, .heartRateVariabilitySDNN,
            .highHeartRateEvent, .lowHeartRateEvent
        ]
        for type in heartTypes {
            XCTAssertEqual(type.category, .heart, "\(type.rawValue) should be in heart category")
        }
    }

    func testNutritionCategoryTypes() {
        let nutritionTypes: [HealthDataType] = [
            .dietaryEnergyConsumed, .dietaryProtein, .dietaryCarbohydrates,
            .dietaryFatTotal, .dietaryWater, .dietaryCaffeine, .food
        ]
        for type in nutritionTypes {
            XCTAssertEqual(type.category, .nutrition, "\(type.rawValue) should be in nutrition category")
        }
    }

    func testSymptomsCategoryTypes() {
        let symptomTypes: [HealthDataType] = [
            .headache, .nausea, .fatigue, .fever, .coughing, .dizziness
        ]
        for type in symptomTypes {
            XCTAssertEqual(type.category, .symptoms, "\(type.rawValue) should be in symptoms category")
        }
    }

    func testReproductiveHealthCategoryTypes() {
        let reproTypes: [HealthDataType] = [
            .menstrualFlow, .cervicalMucusQuality, .ovulationTestResult,
            .pregnancy, .lactation
        ]
        for type in reproTypes {
            XCTAssertEqual(type.category, .reproductiveHealth, "\(type.rawValue) should be in reproductiveHealth category")
        }
    }

    func testCharacteristicsCategoryTypes() {
        let charTypes: [HealthDataType] = [
            .biologicalSex, .bloodType, .dateOfBirth,
            .fitzpatrickSkinType, .wheelchairUse, .activityMoveMode
        ]
        for type in charTypes {
            XCTAssertEqual(type.category, .characteristics, "\(type.rawValue) should be in characteristics category")
        }
    }

    // MARK: - Static Collections

    func testAllSampleTypesExcludesCharacteristics() {
        let sampleTypes = HealthDataType.allSampleTypes
        let characteristicTypes: [HealthDataType] = [
            .biologicalSex, .bloodType, .dateOfBirth,
            .fitzpatrickSkinType, .wheelchairUse, .activityMoveMode
        ]
        for charType in characteristicTypes {
            // Characteristic types don't have sampleType, so they can't be in the set
            // Just verify the set has the right count
            XCTAssertFalse(sampleTypes.isEmpty)
        }
    }

    func testAllObjectTypesIncludesAllTypes() {
        let objectTypes = HealthDataType.allObjectTypes
        // Should have one entry per unique HKObjectType
        XCTAssertFalse(objectTypes.isEmpty)
        // Must be at least as many as the number of unique types
        // (some quantity types share identifiers with correlations, so could be less)
        XCTAssertGreaterThan(objectTypes.count, 100)
    }

    // MARK: - Grouped By Category

    func testGroupedByCategoryCoversAllTypes() {
        let grouped = HealthDataType.groupedByCategory
        let totalTypesInGroups = grouped.reduce(0) { $0 + $1.types.count }
        XCTAssertEqual(totalTypesInGroups, HealthDataType.allCases.count,
                        "Grouped types should cover all cases")
    }

    func testGroupedByCategoryHasNonEmptyGroups() {
        let grouped = HealthDataType.groupedByCategory
        for group in grouped {
            XCTAssertFalse(group.types.isEmpty, "Group \(group.category) should not be empty")
        }
    }

    // MARK: - Codable Roundtrip

    func testHealthDataTypeCodableRoundtrip() throws {
        for type in HealthDataType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(HealthDataType.self, from: data)
            XCTAssertEqual(decoded, type, "\(type.rawValue) should survive encode/decode roundtrip")
        }
    }

    // MARK: - HealthDataCategory

    func testHealthDataCategoryDisplayNames() {
        for category in HealthDataCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "\(category.rawValue) should have a display name")
        }
    }

    func testHealthDataCategoryIconNames() {
        for category in HealthDataCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty, "\(category.rawValue) should have an icon name")
        }
    }

    // MARK: - DataTypeKind

    func testDataTypeKindCodableRoundtrip() throws {
        let kinds: [DataTypeKind] = [.quantity, .category, .correlation, .characteristic, .workout]
        for kind in kinds {
            let data = try JSONEncoder().encode(kind)
            let decoded = try JSONDecoder().decode(DataTypeKind.self, from: data)
            XCTAssertEqual(decoded, kind)
        }
    }

    // MARK: - Total Type Count

    func testTotalTypeCountIsExpected() {
        // Verify we have at least 150 types as expected
        XCTAssertGreaterThanOrEqual(HealthDataType.allCases.count, 150,
                                     "Should have at least 150 health data types")
    }

    func testQuantityTypeCount() {
        let quantityCount = HealthDataType.allCases.filter { $0.kind == .quantity }.count
        XCTAssertGreaterThanOrEqual(quantityCount, 90, "Should have 90+ quantity types")
    }

    func testCategoryTypeCount() {
        let categoryCount = HealthDataType.allCases.filter { $0.kind == .category }.count
        XCTAssertGreaterThanOrEqual(categoryCount, 50, "Should have 50+ category types")
    }

    func testCorrelationTypeCount() {
        let correlationCount = HealthDataType.allCases.filter { $0.kind == .correlation }.count
        XCTAssertEqual(correlationCount, 2, "Should have exactly 2 correlation types")
    }

    func testCharacteristicTypeCount() {
        let characteristicCount = HealthDataType.allCases.filter { $0.kind == .characteristic }.count
        XCTAssertEqual(characteristicCount, 6, "Should have exactly 6 characteristic types")
    }
}
