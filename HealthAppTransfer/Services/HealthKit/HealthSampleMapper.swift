import Foundation
import HealthKit

// MARK: - Health Sample Mapper

/// Maps HKSample instances to HealthSampleDTO for JSON serialization.
enum HealthSampleMapper {

    /// Map an HKSample to a HealthSampleDTO for a given data type.
    static func map(_ sample: HKSample, type: HealthDataType) -> HealthSampleDTO? {
        let sourceName = sample.sourceRevision.source.name
        let bundleId = sample.sourceRevision.source.bundleIdentifier

        let metadataJSON = encodeMetadata(sample.metadata)

        switch sample {
        case let quantitySample as HKQuantitySample:
            guard type.isQuantityType else { return nil }
            let unit = preferredUnit(for: type)
            let value = quantitySample.quantity.doubleValue(for: unit)

            return HealthSampleDTO(
                id: sample.uuid,
                type: type,
                startDate: sample.startDate,
                endDate: sample.endDate,
                sourceName: sourceName,
                sourceBundleIdentifier: bundleId,
                value: value,
                unit: unit.unitString,
                categoryValue: nil,
                workoutActivityType: nil,
                workoutDuration: nil,
                workoutTotalEnergyBurned: nil,
                workoutTotalDistance: nil,
                correlationValues: nil,
                characteristicValue: nil,
                metadataJSON: metadataJSON
            )

        case let categorySample as HKCategorySample:
            return HealthSampleDTO(
                id: sample.uuid,
                type: type,
                startDate: sample.startDate,
                endDate: sample.endDate,
                sourceName: sourceName,
                sourceBundleIdentifier: bundleId,
                value: nil,
                unit: nil,
                categoryValue: categorySample.value,
                workoutActivityType: nil,
                workoutDuration: nil,
                workoutTotalEnergyBurned: nil,
                workoutTotalDistance: nil,
                correlationValues: nil,
                characteristicValue: nil,
                metadataJSON: metadataJSON
            )

        case let workout as HKWorkout:
            return HealthSampleDTO(
                id: sample.uuid,
                type: type,
                startDate: sample.startDate,
                endDate: sample.endDate,
                sourceName: sourceName,
                sourceBundleIdentifier: bundleId,
                value: nil,
                unit: nil,
                categoryValue: nil,
                workoutActivityType: workout.workoutActivityType.rawValue,
                workoutDuration: workout.duration,
                workoutTotalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                workoutTotalDistance: workout.totalDistance?.doubleValue(for: .meter()),
                correlationValues: nil,
                characteristicValue: nil,
                metadataJSON: metadataJSON
            )

        case let correlation as HKCorrelation:
            return mapCorrelation(correlation, type: type, sourceName: sourceName, bundleId: bundleId, metadataJSON: metadataJSON)

        default:
            return nil
        }
    }

    /// Map an array of HKSamples.
    static func map(_ samples: [HKSample], type: HealthDataType) -> [HealthSampleDTO] {
        samples.compactMap { map($0, type: type) }
    }

    // MARK: - Correlation Mapping

    private static func mapCorrelation(
        _ correlation: HKCorrelation,
        type: HealthDataType,
        sourceName: String,
        bundleId: String?,
        metadataJSON: String?
    ) -> HealthSampleDTO? {
        var subValues: [String: Double] = [:]

        switch type {
        case .bloodPressure:
            if let systolic = correlation.objects(for: HKQuantityType(.bloodPressureSystolic)).first as? HKQuantitySample {
                subValues["systolic"] = systolic.quantity.doubleValue(for: .millimeterOfMercury())
            }
            if let diastolic = correlation.objects(for: HKQuantityType(.bloodPressureDiastolic)).first as? HKQuantitySample {
                subValues["diastolic"] = diastolic.quantity.doubleValue(for: .millimeterOfMercury())
            }

        case .food:
            for object in correlation.objects {
                guard let quantitySample = object as? HKQuantitySample else { continue }
                let typeId = quantitySample.quantityType.identifier
                if let dataType = HealthDataType.allCases.first(where: {
                    $0.isQuantityType && HKQuantityType($0.quantityTypeIdentifier).identifier == typeId
                }) {
                    let unit = preferredUnit(for: dataType)
                    subValues[dataType.rawValue] = quantitySample.quantity.doubleValue(for: unit)
                }
            }

        default:
            return nil
        }

        return HealthSampleDTO(
            id: correlation.uuid,
            type: type,
            startDate: correlation.startDate,
            endDate: correlation.endDate,
            sourceName: sourceName,
            sourceBundleIdentifier: bundleId,
            value: nil,
            unit: type == .bloodPressure ? "mmHg" : nil,
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: subValues.isEmpty ? nil : subValues,
            characteristicValue: nil,
            metadataJSON: metadataJSON
        )
    }

    // MARK: - Characteristic Mapping

    /// Map a characteristic type to a DTO. The caller provides the string value read from the store.
    static func mapCharacteristic(_ type: HealthDataType, stringValue: String) -> HealthSampleDTO {
        HealthSampleDTO(
            id: UUID(),
            type: type,
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
            characteristicValue: stringValue,
            metadataJSON: nil
        )
    }

    /// Read a characteristic value from the HealthKit store as a string.
    static func readCharacteristic(_ type: HealthDataType, from store: HKHealthStore) -> String? {
        switch type {
        case .biologicalSex:
            guard let sex = try? store.biologicalSex().biologicalSex else { return nil }
            return biologicalSexString(sex)
        case .bloodType:
            guard let blood = try? store.bloodType().bloodType else { return nil }
            return bloodTypeString(blood)
        case .dateOfBirth:
            guard let components = try? store.dateOfBirthComponents(),
                  let date = Calendar.current.date(from: components) else { return nil }
            return ISO8601DateFormatter().string(from: date)
        case .fitzpatrickSkinType:
            guard let skin = try? store.fitzpatrickSkinType().skinType else { return nil }
            return fitzpatrickSkinTypeString(skin)
        case .wheelchairUse:
            guard let wheelchair = try? store.wheelchairUse().wheelchairUse else { return nil }
            return wheelchairUseString(wheelchair)
        case .activityMoveMode:
            guard let mode = try? store.activityMoveMode().activityMoveMode else { return nil }
            return activityMoveModeString(mode)
        default:
            return nil
        }
    }

    // MARK: - Characteristic Value Strings

    private static func biologicalSexString(_ sex: HKBiologicalSex) -> String {
        switch sex {
        case .female: return "female"
        case .male: return "male"
        case .other: return "other"
        case .notSet: return "notSet"
        @unknown default: return "unknown"
        }
    }

    private static func bloodTypeString(_ type: HKBloodType) -> String {
        switch type {
        case .aPositive: return "A+"
        case .aNegative: return "A-"
        case .bPositive: return "B+"
        case .bNegative: return "B-"
        case .abPositive: return "AB+"
        case .abNegative: return "AB-"
        case .oPositive: return "O+"
        case .oNegative: return "O-"
        case .notSet: return "notSet"
        @unknown default: return "unknown"
        }
    }

    private static func fitzpatrickSkinTypeString(_ type: HKFitzpatrickSkinType) -> String {
        switch type {
        case .I: return "I"
        case .II: return "II"
        case .III: return "III"
        case .IV: return "IV"
        case .V: return "V"
        case .VI: return "VI"
        case .notSet: return "notSet"
        @unknown default: return "unknown"
        }
    }

    private static func wheelchairUseString(_ use: HKWheelchairUse) -> String {
        switch use {
        case .yes: return "yes"
        case .no: return "no"
        case .notSet: return "notSet"
        @unknown default: return "unknown"
        }
    }

    private static func activityMoveModeString(_ mode: HKActivityMoveMode) -> String {
        switch mode {
        case .activeEnergy: return "activeEnergy"
        case .appleMoveTime: return "appleMoveTime"
        @unknown default: return "unknown"
        }
    }

    // MARK: - Unit Mapping

    /// Returns the preferred HKUnit for a given quantity data type.
    static func preferredUnit(for type: HealthDataType) -> HKUnit {
        guard let unit = unitMap[type] else {
            assertionFailure("\(type) does not have a preferred HKUnit")
            return .count()
        }
        return unit
    }

    private static let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())
    private static let metersPerSecond = HKUnit.meter().unitDivided(by: .second())
    private static let mgPerDL = HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
    private static let vo2MaxUnit = HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
    private static let litersPerMinute = HKUnit.liter().unitDivided(by: .minute())
    private static let appleEffortScore = HKUnit.kilocalorie().unitDivided(by: HKUnit.hour().unitMultiplied(by: HKUnit.gramUnit(with: .kilo)))

    // swiftlint:disable closure_body_length
    private static let unitMap: [HealthDataType: HKUnit] = [
        // Activity — count
        .stepCount: .count(),
        .flightsClimbed: .count(),
        .pushCount: .count(),
        .swimmingStrokeCount: .count(),
        .nikeFuel: .count(),
        .physicalEffort: appleEffortScore,
        // Activity — distance (meters)
        .distanceWalkingRunning: .meter(),
        .distanceCycling: .meter(),
        .distanceSwimming: .meter(),
        .distanceWheelchair: .meter(),
        .distanceDownhillSnowSports: .meter(),
        .underwaterDepth: .meter(),
        .sixMinuteWalkTestDistance: .meter(),
        // Activity — energy
        .activeEnergyBurned: .kilocalorie(),
        .basalEnergyBurned: .kilocalorie(),
        // Activity — time (minutes)
        .appleExerciseTime: .minute(),
        .appleStandTime: .minute(),
        .appleMoveTime: .minute(),
        // Activity — speed (m/s)
        .cyclingSpeed: metersPerSecond,
        .runningSpeed: metersPerSecond,
        .walkingSpeed: metersPerSecond,
        .stairAscentSpeed: metersPerSecond,
        .stairDescentSpeed: metersPerSecond,
        // Activity — power (watts)
        .cyclingPower: .watt(),
        .cyclingFunctionalThresholdPower: .watt(),
        .runningPower: .watt(),
        // Activity — cadence (count/min)
        .cyclingCadence: beatsPerMinute,
        // Activity — length
        .runningStrideLength: .meter(),
        .walkingStepLength: .meter(),
        .runningVerticalOscillation: .meterUnit(with: .centi),
        // Activity — time (ms)
        .runningGroundContactTime: .secondUnit(with: .milli),
        // Activity — temperature
        .waterTemperature: .degreeCelsius(),
        // Heart — beats per minute
        .heartRate: beatsPerMinute,
        .restingHeartRate: beatsPerMinute,
        .walkingHeartRateAverage: beatsPerMinute,
        .heartRateRecoveryOneMinute: beatsPerMinute,
        // Heart — milliseconds
        .heartRateVariabilitySDNN: .secondUnit(with: .milli),
        // Heart — percent
        .atrialFibrillationBurden: .percent(),
        .peripheralPerfusionIndex: .percent(),
        // Vitals — percent
        .oxygenSaturation: .percent(),
        // Vitals — temperature
        .bodyTemperature: .degreeCelsius(),
        .basalBodyTemperature: .degreeCelsius(),
        .appleSleepingWristTemperature: .degreeCelsius(),
        // Vitals — pressure
        .bloodPressureSystolic: .millimeterOfMercury(),
        .bloodPressureDiastolic: .millimeterOfMercury(),
        // Vitals — rate
        .respiratoryRate: beatsPerMinute,
        // Body Measurements — mass
        .bodyMass: .gramUnit(with: .kilo),
        .leanBodyMass: .gramUnit(with: .kilo),
        // Body Measurements — dimensionless
        .bodyMassIndex: .count(),
        // Body Measurements — percent
        .bodyFatPercentage: .percent(),
        // Body Measurements — length
        .height: .meterUnit(with: .centi),
        .waistCircumference: .meterUnit(with: .centi),
        // Body Measurements — conductance
        .electrodermalActivity: HKUnit(from: "µS"),
        // Metabolic
        .bloodGlucose: mgPerDL,
        .insulinDelivery: .internationalUnit(),
        .numberOfAlcoholicBeverages: .count(),
        .bloodAlcoholContent: .percent(),
        // Nutrition — energy
        .dietaryEnergyConsumed: .kilocalorie(),
        // Nutrition — grams (macros)
        .dietaryCarbohydrates: .gram(),
        .dietaryFatTotal: .gram(),
        .dietaryFatPolyunsaturated: .gram(),
        .dietaryFatMonounsaturated: .gram(),
        .dietaryFatSaturated: .gram(),
        .dietaryCholesterol: .gram(),
        .dietaryProtein: .gram(),
        .dietarySugar: .gram(),
        .dietaryFiber: .gram(),
        // Nutrition — grams (minerals & vitamins)
        .dietarySodium: .gram(),
        .dietaryCalcium: .gram(),
        .dietaryIron: .gram(),
        .dietaryPotassium: .gram(),
        .dietaryVitaminA: .gram(),
        .dietaryVitaminB6: .gram(),
        .dietaryVitaminB12: .gram(),
        .dietaryVitaminC: .gram(),
        .dietaryVitaminD: .gram(),
        .dietaryVitaminE: .gram(),
        .dietaryVitaminK: .gram(),
        .dietaryBiotin: .gram(),
        .dietaryThiamin: .gram(),
        .dietaryRiboflavin: .gram(),
        .dietaryNiacin: .gram(),
        .dietaryFolate: .gram(),
        .dietaryPantothenicAcid: .gram(),
        .dietaryPhosphorus: .gram(),
        .dietaryIodine: .gram(),
        .dietaryMagnesium: .gram(),
        .dietaryZinc: .gram(),
        .dietarySelenium: .gram(),
        .dietaryCopper: .gram(),
        .dietaryManganese: .gram(),
        .dietaryChromium: .gram(),
        .dietaryMolybdenum: .gram(),
        .dietaryChloride: .gram(),
        .dietaryCaffeine: .gram(),
        // Nutrition — volume
        .dietaryWater: .literUnit(with: .milli),
        // Respiratory
        .peakExpiratoryFlowRate: litersPerMinute,
        .forcedExpiratoryVolume1: .liter(),
        .forcedVitalCapacity: .liter(),
        .inhalerUsage: .count(),
        // Mobility — percent
        .walkingDoubleSupportPercentage: .percent(),
        .walkingAsymmetryPercentage: .percent(),
        .appleWalkingSteadiness: .percent(),
        // Fitness
        .vo2Max: vo2MaxUnit,
        // Audio Exposure
        .environmentalAudioExposure: .decibelAWeightedSoundPressureLevel(),
        .headphoneAudioExposure: .decibelAWeightedSoundPressureLevel(),
        // Other
        .uvExposure: .count(),
        .numberOfTimesFallen: .count(),
        .timeInDaylight: .minute(),
    ]
    // swiftlint:enable closure_body_length

    // MARK: - Metadata Encoding

    private static func encodeMetadata(_ metadata: [String: Any]?) -> String? {
        guard let metadata, !metadata.isEmpty else { return nil }

        // Filter to JSON-serializable values only
        let filtered = metadata.compactMapValues { value -> Any? in
            switch value {
            case is String, is Int, is Double, is Bool:
                return value
            case let date as Date:
                return ISO8601DateFormatter().string(from: date)
            default:
                return String(describing: value)
            }
        }

        guard let data = try? JSONSerialization.data(withJSONObject: filtered),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
