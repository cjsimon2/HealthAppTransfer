import Foundation
import HealthKit

// MARK: - Data Type Kind

/// Classifies a HealthDataType by its underlying HealthKit type.
enum DataTypeKind: String, Codable, Sendable {
    case quantity
    case category
    case correlation
    case characteristic
    case workout
}

// MARK: - Health Data Category

/// UI grouping for health data types.
enum HealthDataCategory: String, CaseIterable, Codable, Sendable {
    case activity
    case heart
    case vitals
    case bodyMeasurements
    case metabolic
    case nutrition
    case respiratory
    case mobility
    case fitness
    case audioExposure
    case sleep
    case mindfulness
    case reproductiveHealth
    case symptoms
    case other
    case workout
    case characteristics

    var displayName: String {
        switch self {
        case .activity: return String(localized: "category.activity", defaultValue: "Activity")
        case .heart: return String(localized: "category.heart", defaultValue: "Heart")
        case .vitals: return String(localized: "category.vitals", defaultValue: "Vitals")
        case .bodyMeasurements: return String(localized: "category.bodyMeasurements", defaultValue: "Body Measurements")
        case .metabolic: return String(localized: "category.metabolic", defaultValue: "Metabolic")
        case .nutrition: return String(localized: "category.nutrition", defaultValue: "Nutrition")
        case .respiratory: return String(localized: "category.respiratory", defaultValue: "Respiratory")
        case .mobility: return String(localized: "category.mobility", defaultValue: "Mobility")
        case .fitness: return String(localized: "category.fitness", defaultValue: "Fitness")
        case .audioExposure: return String(localized: "category.audioExposure", defaultValue: "Audio Exposure")
        case .sleep: return String(localized: "category.sleep", defaultValue: "Sleep")
        case .mindfulness: return String(localized: "category.mindfulness", defaultValue: "Mindfulness")
        case .reproductiveHealth: return String(localized: "category.reproductiveHealth", defaultValue: "Reproductive Health")
        case .symptoms: return String(localized: "category.symptoms", defaultValue: "Symptoms")
        case .other: return String(localized: "category.other", defaultValue: "Other")
        case .workout: return String(localized: "category.workouts", defaultValue: "Workouts")
        case .characteristics: return String(localized: "category.characteristics", defaultValue: "Characteristics")
        }
    }

    var iconName: String {
        switch self {
        case .activity: return "flame.fill"
        case .heart: return "heart.fill"
        case .vitals: return "waveform.path.ecg"
        case .bodyMeasurements: return "figure"
        case .metabolic: return "drop.fill"
        case .nutrition: return "fork.knife"
        case .respiratory: return "lungs.fill"
        case .mobility: return "figure.walk"
        case .fitness: return "sportscourt.fill"
        case .audioExposure: return "ear.fill"
        case .sleep: return "bed.double.fill"
        case .mindfulness: return "brain.head.profile"
        case .reproductiveHealth: return "heart.circle.fill"
        case .symptoms: return "staroflife.fill"
        case .other: return "ellipsis.circle.fill"
        case .workout: return "figure.run"
        case .characteristics: return "person.fill"
        }
    }
}

// MARK: - Grouped Types Helper

extension HealthDataType {

    /// Returns all types grouped by their category, preserving category order.
    static var groupedByCategory: [(category: HealthDataCategory, types: [HealthDataType])] {
        var groups: [HealthDataCategory: [HealthDataType]] = [:]
        for type in allCases {
            groups[type.category, default: []].append(type)
        }
        return HealthDataCategory.allCases.compactMap { category in
            guard let types = groups[category], !types.isEmpty else { return nil }
            return (category: category, types: types)
        }
    }
}

// MARK: - Health Data Type

/// All HealthKit data types supported for transfer.
enum HealthDataType: String, CaseIterable, Codable, Sendable {

    // MARK: - Activity (Quantity)
    case stepCount
    case distanceWalkingRunning
    case distanceCycling
    case distanceSwimming
    case distanceWheelchair
    case distanceDownhillSnowSports
    case flightsClimbed
    case activeEnergyBurned
    case basalEnergyBurned
    case appleExerciseTime
    case appleStandTime
    case appleMoveTime
    case pushCount
    case swimmingStrokeCount
    case nikeFuel
    case physicalEffort
    case cyclingSpeed
    case cyclingPower
    case cyclingFunctionalThresholdPower
    case cyclingCadence
    case runningSpeed
    case runningPower
    case runningStrideLength
    case runningVerticalOscillation
    case runningGroundContactTime
    case underwaterDepth
    case waterTemperature

    // MARK: - Heart (Quantity)
    case heartRate
    case restingHeartRate
    case walkingHeartRateAverage
    case heartRateVariabilitySDNN
    case heartRateRecoveryOneMinute
    case atrialFibrillationBurden
    case peripheralPerfusionIndex

    // MARK: - Vitals (Quantity)
    case oxygenSaturation
    case bodyTemperature
    case basalBodyTemperature
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case respiratoryRate
    case appleSleepingWristTemperature

    // MARK: - Body Measurements (Quantity)
    case bodyMass
    case bodyMassIndex
    case bodyFatPercentage
    case leanBodyMass
    case height
    case waistCircumference
    case electrodermalActivity

    // MARK: - Metabolic (Quantity)
    case bloodGlucose
    case insulinDelivery
    case numberOfAlcoholicBeverages
    case bloodAlcoholContent

    // MARK: - Nutrition (Quantity)
    case dietaryEnergyConsumed
    case dietaryCarbohydrates
    case dietaryFatTotal
    case dietaryFatPolyunsaturated
    case dietaryFatMonounsaturated
    case dietaryFatSaturated
    case dietaryCholesterol
    case dietaryProtein
    case dietarySugar
    case dietaryFiber
    case dietarySodium
    case dietaryCalcium
    case dietaryIron
    case dietaryPotassium
    case dietaryVitaminA
    case dietaryVitaminB6
    case dietaryVitaminB12
    case dietaryVitaminC
    case dietaryVitaminD
    case dietaryVitaminE
    case dietaryVitaminK
    case dietaryBiotin
    case dietaryThiamin
    case dietaryRiboflavin
    case dietaryNiacin
    case dietaryFolate
    case dietaryPantothenicAcid
    case dietaryPhosphorus
    case dietaryIodine
    case dietaryMagnesium
    case dietaryZinc
    case dietarySelenium
    case dietaryCopper
    case dietaryManganese
    case dietaryChromium
    case dietaryMolybdenum
    case dietaryChloride
    case dietaryWater
    case dietaryCaffeine

    // MARK: - Respiratory (Quantity)
    case peakExpiratoryFlowRate
    case forcedExpiratoryVolume1
    case forcedVitalCapacity
    case inhalerUsage

    // MARK: - Mobility (Quantity)
    case walkingSpeed
    case walkingStepLength
    case walkingDoubleSupportPercentage
    case walkingAsymmetryPercentage
    case sixMinuteWalkTestDistance
    case stairAscentSpeed
    case stairDescentSpeed
    case appleWalkingSteadiness

    // MARK: - Fitness (Quantity)
    case vo2Max

    // MARK: - Audio Exposure (Quantity)
    case environmentalAudioExposure
    case headphoneAudioExposure

    // MARK: - Other Measurements (Quantity)
    case uvExposure
    case numberOfTimesFallen
    case timeInDaylight

    // MARK: - Sleep (Category)
    case sleepAnalysis

    // MARK: - Mindfulness (Category)
    case mindfulSession

    // MARK: - Activity Events (Category)
    case appleStandHour

    // MARK: - Heart Events (Category)
    case highHeartRateEvent
    case lowHeartRateEvent
    case irregularHeartRhythmEvent
    case lowCardioFitnessEvent

    // MARK: - Reproductive Health (Category)
    case menstrualFlow
    case cervicalMucusQuality
    case ovulationTestResult
    case sexualActivity
    case intermenstrualBleeding
    case contraceptive
    case lactation
    case pregnancy
    case pregnancyTestResult
    case progesteroneTestResult
    case infrequentMenstrualCycles
    case irregularMenstrualCycles
    case prolongedMenstrualPeriods
    case persistentIntermenstrualBleeding

    // MARK: - Symptoms (Category)
    case abdominalCramps
    case acne
    case appetiteChanges
    case bladderIncontinence
    case bloating
    case breastPain
    case chestTightnessOrPain
    case chills
    case constipation
    case coughing
    case diarrhea
    case dizziness
    case drySkin
    case fainting
    case fatigue
    case fever
    case generalizedBodyAche
    case hairLoss
    case headache
    case heartburn
    case hotFlashes
    case lossOfSmell
    case lossOfTaste
    case lowerBackPain
    case memoryLapse
    case moodChanges
    case nausea
    case nightSweats
    case pelvicPain
    case rapidPoundingOrFlutteringHeartbeat
    case runnyNose
    case shortnessOfBreath
    case sinusCongestion
    case skippedHeartbeat
    case sleepChanges
    case soreThroat
    case vaginalDryness
    case vomiting
    case wheezing

    // MARK: - Hygiene (Category)
    case toothbrushingEvent
    case handwashingEvent

    // MARK: - Audio Events (Category)
    case environmentalAudioExposureEvent
    case headphoneAudioExposureEvent

    // MARK: - Correlations
    case bloodPressure
    case food

    // MARK: - Characteristics
    case biologicalSex
    case bloodType
    case dateOfBirth
    case fitzpatrickSkinType
    case wheelchairUse
    case activityMoveMode

    // MARK: - Workouts
    case workout
}

// MARK: - Core Properties

extension HealthDataType {

    /// The underlying HealthKit type kind.
    var kind: DataTypeKind {
        if Self.quantityIdentifiers[self] != nil { return .quantity }
        if Self.categoryIdentifiers[self] != nil { return .category }
        if Self.correlationIdentifiers[self] != nil { return .correlation }
        if Self.characteristicIdentifiers[self] != nil { return .characteristic }
        if self == .workout { return .workout }
        assertionFailure("No kind defined for \(self)")
        return .quantity
    }

    /// UI category for grouping.
    var category: HealthDataCategory {
        switch self {
        case .stepCount, .distanceWalkingRunning, .distanceCycling, .distanceSwimming,
             .distanceWheelchair, .distanceDownhillSnowSports, .flightsClimbed,
             .activeEnergyBurned, .basalEnergyBurned, .appleExerciseTime, .appleStandTime,
             .appleMoveTime, .pushCount, .swimmingStrokeCount, .nikeFuel, .physicalEffort,
             .cyclingSpeed, .cyclingPower, .cyclingFunctionalThresholdPower, .cyclingCadence,
             .runningSpeed, .runningPower, .runningStrideLength, .runningVerticalOscillation,
             .runningGroundContactTime, .underwaterDepth, .waterTemperature, .appleStandHour:
            return .activity

        case .heartRate, .restingHeartRate, .walkingHeartRateAverage, .heartRateVariabilitySDNN,
             .heartRateRecoveryOneMinute, .atrialFibrillationBurden, .peripheralPerfusionIndex,
             .highHeartRateEvent, .lowHeartRateEvent, .irregularHeartRhythmEvent, .lowCardioFitnessEvent:
            return .heart

        case .oxygenSaturation, .bodyTemperature, .basalBodyTemperature,
             .bloodPressureSystolic, .bloodPressureDiastolic, .respiratoryRate,
             .appleSleepingWristTemperature, .bloodPressure:
            return .vitals

        case .bodyMass, .bodyMassIndex, .bodyFatPercentage, .leanBodyMass,
             .height, .waistCircumference, .electrodermalActivity:
            return .bodyMeasurements

        case .bloodGlucose, .insulinDelivery, .numberOfAlcoholicBeverages, .bloodAlcoholContent:
            return .metabolic

        case .dietaryEnergyConsumed, .dietaryCarbohydrates, .dietaryFatTotal,
             .dietaryFatPolyunsaturated, .dietaryFatMonounsaturated, .dietaryFatSaturated,
             .dietaryCholesterol, .dietaryProtein, .dietarySugar, .dietaryFiber,
             .dietarySodium, .dietaryCalcium, .dietaryIron, .dietaryPotassium,
             .dietaryVitaminA, .dietaryVitaminB6, .dietaryVitaminB12, .dietaryVitaminC,
             .dietaryVitaminD, .dietaryVitaminE, .dietaryVitaminK, .dietaryBiotin,
             .dietaryThiamin, .dietaryRiboflavin, .dietaryNiacin, .dietaryFolate,
             .dietaryPantothenicAcid, .dietaryPhosphorus, .dietaryIodine, .dietaryMagnesium,
             .dietaryZinc, .dietarySelenium, .dietaryCopper, .dietaryManganese,
             .dietaryChromium, .dietaryMolybdenum, .dietaryChloride, .dietaryWater,
             .dietaryCaffeine, .food:
            return .nutrition

        case .peakExpiratoryFlowRate, .forcedExpiratoryVolume1, .forcedVitalCapacity, .inhalerUsage:
            return .respiratory

        case .walkingSpeed, .walkingStepLength, .walkingDoubleSupportPercentage,
             .walkingAsymmetryPercentage, .sixMinuteWalkTestDistance,
             .stairAscentSpeed, .stairDescentSpeed, .appleWalkingSteadiness:
            return .mobility

        case .vo2Max:
            return .fitness

        case .environmentalAudioExposure, .headphoneAudioExposure,
             .environmentalAudioExposureEvent, .headphoneAudioExposureEvent:
            return .audioExposure

        case .sleepAnalysis:
            return .sleep

        case .mindfulSession:
            return .mindfulness

        case .menstrualFlow, .cervicalMucusQuality, .ovulationTestResult, .sexualActivity,
             .intermenstrualBleeding, .contraceptive, .lactation, .pregnancy,
             .pregnancyTestResult, .progesteroneTestResult, .infrequentMenstrualCycles,
             .irregularMenstrualCycles, .prolongedMenstrualPeriods, .persistentIntermenstrualBleeding:
            return .reproductiveHealth

        case .abdominalCramps, .acne, .appetiteChanges, .bladderIncontinence, .bloating,
             .breastPain, .chestTightnessOrPain, .chills, .constipation, .coughing,
             .diarrhea, .dizziness, .drySkin, .fainting, .fatigue, .fever,
             .generalizedBodyAche, .hairLoss, .headache, .heartburn, .hotFlashes,
             .lossOfSmell, .lossOfTaste, .lowerBackPain, .memoryLapse, .moodChanges,
             .nausea, .nightSweats, .pelvicPain, .rapidPoundingOrFlutteringHeartbeat,
             .runnyNose, .shortnessOfBreath, .sinusCongestion, .skippedHeartbeat,
             .sleepChanges, .soreThroat, .vaginalDryness, .vomiting, .wheezing:
            return .symptoms

        case .uvExposure, .numberOfTimesFallen, .timeInDaylight,
             .toothbrushingEvent, .handwashingEvent:
            return .other

        case .workout:
            return .workout

        case .biologicalSex, .bloodType, .dateOfBirth, .fitzpatrickSkinType,
             .wheelchairUse, .activityMoveMode:
            return .characteristics
        }
    }

    /// Whether this type can be queried as an HKSampleType.
    var isSampleBased: Bool {
        kind != .characteristic
    }

    /// Whether this is a quantity type (vs. category, correlation, characteristic, or workout).
    var isQuantityType: Bool {
        kind == .quantity
    }
}

// MARK: - HealthKit Mapping

extension HealthDataType {

    /// The corresponding `HKObjectType` for authorization requests. Works for all types.
    var objectType: HKObjectType {
        switch kind {
        case .quantity:
            return HKQuantityType(quantityTypeIdentifier)
        case .category:
            return HKCategoryType(categoryTypeIdentifier)
        case .correlation:
            return HKCorrelationType(correlationTypeIdentifier)
        case .characteristic:
            return HKCharacteristicType(characteristicTypeIdentifier)
        case .workout:
            return HKWorkoutType.workoutType()
        }
    }

    /// The corresponding `HKSampleType` for reading from HealthKit.
    /// Fatal error if called on characteristic types (use `objectType` instead).
    var sampleType: HKSampleType {
        switch kind {
        case .quantity:
            return HKQuantityType(quantityTypeIdentifier)
        case .category:
            return HKCategoryType(categoryTypeIdentifier)
        case .correlation:
            return HKCorrelationType(correlationTypeIdentifier)
        case .workout:
            return HKWorkoutType.workoutType()
        case .characteristic:
            assertionFailure("\(self) is a characteristic type with no sample type")
            return HKWorkoutType.workoutType()
        }
    }

    /// The corresponding `HKQuantityTypeIdentifier`. Fatal error for non-quantity types.
    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        guard let id = Self.quantityIdentifiers[self] else {
            assertionFailure("\(self) is not a quantity type")
            return .stepCount
        }
        return id
    }

    /// The corresponding `HKCategoryTypeIdentifier`.
    var categoryTypeIdentifier: HKCategoryTypeIdentifier {
        guard let id = Self.categoryIdentifiers[self] else {
            assertionFailure("\(self) is not a category type")
            return .sleepAnalysis
        }
        return id
    }

    /// The corresponding `HKCorrelationTypeIdentifier`.
    var correlationTypeIdentifier: HKCorrelationTypeIdentifier {
        guard let id = Self.correlationIdentifiers[self] else {
            assertionFailure("\(self) is not a correlation type")
            return .bloodPressure
        }
        return id
    }

    /// The corresponding `HKCharacteristicTypeIdentifier`.
    var characteristicTypeIdentifier: HKCharacteristicTypeIdentifier {
        guard let id = Self.characteristicIdentifiers[self] else {
            assertionFailure("\(self) is not a characteristic type")
            return .biologicalSex
        }
        return id
    }
}

// MARK: - Display Properties

extension HealthDataType {

    /// Human-readable display name.
    var displayName: String {
        Self.displayNames[self] ?? rawValue
    }
}

// MARK: - Static Collections

extension HealthDataType {

    /// All sample-based types as a Set for HealthKit sample queries.
    static var allSampleTypes: Set<HKSampleType> {
        Set(allCases.filter(\.isSampleBased).map(\.sampleType))
    }

    /// All types as HKObjectType for HealthKit authorization requests.
    /// Excludes correlation types — HealthKit disallows reading them directly;
    /// their component quantity types (already included) provide the authorization.
    static var allObjectTypes: Set<HKObjectType> {
        Set(allCases.filter { $0.kind != .correlation }.map(\.objectType))
    }
}

// MARK: - Quantity Type Identifiers

private extension HealthDataType {

    static let quantityIdentifiers: [HealthDataType: HKQuantityTypeIdentifier] = [
        // Activity
        .stepCount: .stepCount,
        .distanceWalkingRunning: .distanceWalkingRunning,
        .distanceCycling: .distanceCycling,
        .distanceSwimming: .distanceSwimming,
        .distanceWheelchair: .distanceWheelchair,
        .distanceDownhillSnowSports: .distanceDownhillSnowSports,
        .flightsClimbed: .flightsClimbed,
        .activeEnergyBurned: .activeEnergyBurned,
        .basalEnergyBurned: .basalEnergyBurned,
        .appleExerciseTime: .appleExerciseTime,
        .appleStandTime: .appleStandTime,
        .appleMoveTime: .appleMoveTime,
        .pushCount: .pushCount,
        .swimmingStrokeCount: .swimmingStrokeCount,
        .nikeFuel: .nikeFuel,
        .physicalEffort: .physicalEffort,
        .cyclingSpeed: .cyclingSpeed,
        .cyclingPower: .cyclingPower,
        .cyclingFunctionalThresholdPower: .cyclingFunctionalThresholdPower,
        .cyclingCadence: .cyclingCadence,
        .runningSpeed: .runningSpeed,
        .runningPower: .runningPower,
        .runningStrideLength: .runningStrideLength,
        .runningVerticalOscillation: .runningVerticalOscillation,
        .runningGroundContactTime: .runningGroundContactTime,
        .underwaterDepth: .underwaterDepth,
        .waterTemperature: .waterTemperature,
        // Heart
        .heartRate: .heartRate,
        .restingHeartRate: .restingHeartRate,
        .walkingHeartRateAverage: .walkingHeartRateAverage,
        .heartRateVariabilitySDNN: .heartRateVariabilitySDNN,
        .heartRateRecoveryOneMinute: .heartRateRecoveryOneMinute,
        .atrialFibrillationBurden: .atrialFibrillationBurden,
        .peripheralPerfusionIndex: .peripheralPerfusionIndex,
        // Vitals
        .oxygenSaturation: .oxygenSaturation,
        .bodyTemperature: .bodyTemperature,
        .basalBodyTemperature: .basalBodyTemperature,
        .bloodPressureSystolic: .bloodPressureSystolic,
        .bloodPressureDiastolic: .bloodPressureDiastolic,
        .respiratoryRate: .respiratoryRate,
        .appleSleepingWristTemperature: .appleSleepingWristTemperature,
        // Body Measurements
        .bodyMass: .bodyMass,
        .bodyMassIndex: .bodyMassIndex,
        .bodyFatPercentage: .bodyFatPercentage,
        .leanBodyMass: .leanBodyMass,
        .height: .height,
        .waistCircumference: .waistCircumference,
        .electrodermalActivity: .electrodermalActivity,
        // Metabolic
        .bloodGlucose: .bloodGlucose,
        .insulinDelivery: .insulinDelivery,
        .numberOfAlcoholicBeverages: .numberOfAlcoholicBeverages,
        .bloodAlcoholContent: .bloodAlcoholContent,
        // Nutrition
        .dietaryEnergyConsumed: .dietaryEnergyConsumed,
        .dietaryCarbohydrates: .dietaryCarbohydrates,
        .dietaryFatTotal: .dietaryFatTotal,
        .dietaryFatPolyunsaturated: .dietaryFatPolyunsaturated,
        .dietaryFatMonounsaturated: .dietaryFatMonounsaturated,
        .dietaryFatSaturated: .dietaryFatSaturated,
        .dietaryCholesterol: .dietaryCholesterol,
        .dietaryProtein: .dietaryProtein,
        .dietarySugar: .dietarySugar,
        .dietaryFiber: .dietaryFiber,
        .dietarySodium: .dietarySodium,
        .dietaryCalcium: .dietaryCalcium,
        .dietaryIron: .dietaryIron,
        .dietaryPotassium: .dietaryPotassium,
        .dietaryVitaminA: .dietaryVitaminA,
        .dietaryVitaminB6: .dietaryVitaminB6,
        .dietaryVitaminB12: .dietaryVitaminB12,
        .dietaryVitaminC: .dietaryVitaminC,
        .dietaryVitaminD: .dietaryVitaminD,
        .dietaryVitaminE: .dietaryVitaminE,
        .dietaryVitaminK: .dietaryVitaminK,
        .dietaryBiotin: .dietaryBiotin,
        .dietaryThiamin: .dietaryThiamin,
        .dietaryRiboflavin: .dietaryRiboflavin,
        .dietaryNiacin: .dietaryNiacin,
        .dietaryFolate: .dietaryFolate,
        .dietaryPantothenicAcid: .dietaryPantothenicAcid,
        .dietaryPhosphorus: .dietaryPhosphorus,
        .dietaryIodine: .dietaryIodine,
        .dietaryMagnesium: .dietaryMagnesium,
        .dietaryZinc: .dietaryZinc,
        .dietarySelenium: .dietarySelenium,
        .dietaryCopper: .dietaryCopper,
        .dietaryManganese: .dietaryManganese,
        .dietaryChromium: .dietaryChromium,
        .dietaryMolybdenum: .dietaryMolybdenum,
        .dietaryChloride: .dietaryChloride,
        .dietaryWater: .dietaryWater,
        .dietaryCaffeine: .dietaryCaffeine,
        // Respiratory
        .peakExpiratoryFlowRate: .peakExpiratoryFlowRate,
        .forcedExpiratoryVolume1: .forcedExpiratoryVolume1,
        .forcedVitalCapacity: .forcedVitalCapacity,
        .inhalerUsage: .inhalerUsage,
        // Mobility
        .walkingSpeed: .walkingSpeed,
        .walkingStepLength: .walkingStepLength,
        .walkingDoubleSupportPercentage: .walkingDoubleSupportPercentage,
        .walkingAsymmetryPercentage: .walkingAsymmetryPercentage,
        .sixMinuteWalkTestDistance: .sixMinuteWalkTestDistance,
        .stairAscentSpeed: .stairAscentSpeed,
        .stairDescentSpeed: .stairDescentSpeed,
        .appleWalkingSteadiness: .appleWalkingSteadiness,
        // Fitness
        .vo2Max: .vo2Max,
        // Audio Exposure
        .environmentalAudioExposure: .environmentalAudioExposure,
        .headphoneAudioExposure: .headphoneAudioExposure,
        // Other
        .uvExposure: .uvExposure,
        .numberOfTimesFallen: .numberOfTimesFallen,
        .timeInDaylight: .timeInDaylight,
    ]
}

// MARK: - Category Type Identifiers

private extension HealthDataType {

    static let categoryIdentifiers: [HealthDataType: HKCategoryTypeIdentifier] = [
        // Sleep & Mindfulness
        .sleepAnalysis: .sleepAnalysis,
        .mindfulSession: .mindfulSession,
        // Activity Events
        .appleStandHour: .appleStandHour,
        // Heart Events
        .highHeartRateEvent: .highHeartRateEvent,
        .lowHeartRateEvent: .lowHeartRateEvent,
        .irregularHeartRhythmEvent: .irregularHeartRhythmEvent,
        .lowCardioFitnessEvent: .lowCardioFitnessEvent,
        // Reproductive Health
        .menstrualFlow: .menstrualFlow,
        .cervicalMucusQuality: .cervicalMucusQuality,
        .ovulationTestResult: .ovulationTestResult,
        .sexualActivity: .sexualActivity,
        .intermenstrualBleeding: .intermenstrualBleeding,
        .contraceptive: .contraceptive,
        .lactation: .lactation,
        .pregnancy: .pregnancy,
        .pregnancyTestResult: .pregnancyTestResult,
        .progesteroneTestResult: .progesteroneTestResult,
        .infrequentMenstrualCycles: .infrequentMenstrualCycles,
        .irregularMenstrualCycles: .irregularMenstrualCycles,
        .prolongedMenstrualPeriods: .prolongedMenstrualPeriods,
        .persistentIntermenstrualBleeding: .persistentIntermenstrualBleeding,
        // Symptoms
        .abdominalCramps: .abdominalCramps,
        .acne: .acne,
        .appetiteChanges: .appetiteChanges,
        .bladderIncontinence: .bladderIncontinence,
        .bloating: .bloating,
        .breastPain: .breastPain,
        .chestTightnessOrPain: .chestTightnessOrPain,
        .chills: .chills,
        .constipation: .constipation,
        .coughing: .coughing,
        .diarrhea: .diarrhea,
        .dizziness: .dizziness,
        .drySkin: .drySkin,
        .fainting: .fainting,
        .fatigue: .fatigue,
        .fever: .fever,
        .generalizedBodyAche: .generalizedBodyAche,
        .hairLoss: .hairLoss,
        .headache: .headache,
        .heartburn: .heartburn,
        .hotFlashes: .hotFlashes,
        .lossOfSmell: .lossOfSmell,
        .lossOfTaste: .lossOfTaste,
        .lowerBackPain: .lowerBackPain,
        .memoryLapse: .memoryLapse,
        .moodChanges: .moodChanges,
        .nausea: .nausea,
        .nightSweats: .nightSweats,
        .pelvicPain: .pelvicPain,
        .rapidPoundingOrFlutteringHeartbeat: .rapidPoundingOrFlutteringHeartbeat,
        .runnyNose: .runnyNose,
        .shortnessOfBreath: .shortnessOfBreath,
        .sinusCongestion: .sinusCongestion,
        .skippedHeartbeat: .skippedHeartbeat,
        .sleepChanges: .sleepChanges,
        .soreThroat: .soreThroat,
        .vaginalDryness: .vaginalDryness,
        .vomiting: .vomiting,
        .wheezing: .wheezing,
        // Hygiene
        .toothbrushingEvent: .toothbrushingEvent,
        .handwashingEvent: .handwashingEvent,
        // Audio Events
        .environmentalAudioExposureEvent: .environmentalAudioExposureEvent,
        .headphoneAudioExposureEvent: .headphoneAudioExposureEvent,
    ]
}

// MARK: - Correlation & Characteristic Identifiers

private extension HealthDataType {

    static let correlationIdentifiers: [HealthDataType: HKCorrelationTypeIdentifier] = [
        .bloodPressure: .bloodPressure,
        .food: .food,
    ]

    static let characteristicIdentifiers: [HealthDataType: HKCharacteristicTypeIdentifier] = [
        .biologicalSex: .biologicalSex,
        .bloodType: .bloodType,
        .dateOfBirth: .dateOfBirth,
        .fitzpatrickSkinType: .fitzpatrickSkinType,
        .wheelchairUse: .wheelchairUse,
        .activityMoveMode: .activityMoveMode,
    ]
}

// MARK: - Display Names

private extension HealthDataType {

    static let displayNames: [HealthDataType: String] = [
        // Activity
        .stepCount: "Step Count",
        .distanceWalkingRunning: "Walking + Running Distance",
        .distanceCycling: "Cycling Distance",
        .distanceSwimming: "Swimming Distance",
        .distanceWheelchair: "Wheelchair Distance",
        .distanceDownhillSnowSports: "Snow Sports Distance",
        .flightsClimbed: "Flights Climbed",
        .activeEnergyBurned: "Active Energy",
        .basalEnergyBurned: "Resting Energy",
        .appleExerciseTime: "Exercise Minutes",
        .appleStandTime: "Stand Minutes",
        .appleMoveTime: "Move Minutes",
        .pushCount: "Push Count",
        .swimmingStrokeCount: "Swimming Strokes",
        .nikeFuel: "Nike Fuel",
        .physicalEffort: "Physical Effort",
        .cyclingSpeed: "Cycling Speed",
        .cyclingPower: "Cycling Power",
        .cyclingFunctionalThresholdPower: "Cycling FTP",
        .cyclingCadence: "Cycling Cadence",
        .runningSpeed: "Running Speed",
        .runningPower: "Running Power",
        .runningStrideLength: "Running Stride Length",
        .runningVerticalOscillation: "Running Vertical Oscillation",
        .runningGroundContactTime: "Ground Contact Time",
        .underwaterDepth: "Underwater Depth",
        .waterTemperature: "Water Temperature",
        // Heart
        .heartRate: "Heart Rate",
        .restingHeartRate: "Resting Heart Rate",
        .walkingHeartRateAverage: "Walking Heart Rate",
        .heartRateVariabilitySDNN: "Heart Rate Variability",
        .heartRateRecoveryOneMinute: "Heart Rate Recovery",
        .atrialFibrillationBurden: "AFib Burden",
        .peripheralPerfusionIndex: "Perfusion Index",
        // Vitals
        .oxygenSaturation: "Blood Oxygen",
        .bodyTemperature: "Body Temperature",
        .basalBodyTemperature: "Basal Body Temperature",
        .bloodPressureSystolic: "Blood Pressure (Systolic)",
        .bloodPressureDiastolic: "Blood Pressure (Diastolic)",
        .respiratoryRate: "Respiratory Rate",
        .appleSleepingWristTemperature: "Wrist Temperature (Sleep)",
        // Body Measurements
        .bodyMass: "Weight",
        .bodyMassIndex: "BMI",
        .bodyFatPercentage: "Body Fat",
        .leanBodyMass: "Lean Body Mass",
        .height: "Height",
        .waistCircumference: "Waist Circumference",
        .electrodermalActivity: "Electrodermal Activity",
        // Metabolic
        .bloodGlucose: "Blood Glucose",
        .insulinDelivery: "Insulin Delivery",
        .numberOfAlcoholicBeverages: "Alcoholic Beverages",
        .bloodAlcoholContent: "Blood Alcohol Content",
        // Nutrition
        .dietaryEnergyConsumed: "Dietary Energy",
        .dietaryCarbohydrates: "Carbohydrates",
        .dietaryFatTotal: "Total Fat",
        .dietaryFatPolyunsaturated: "Polyunsaturated Fat",
        .dietaryFatMonounsaturated: "Monounsaturated Fat",
        .dietaryFatSaturated: "Saturated Fat",
        .dietaryCholesterol: "Cholesterol",
        .dietaryProtein: "Protein",
        .dietarySugar: "Sugar",
        .dietaryFiber: "Fiber",
        .dietarySodium: "Sodium",
        .dietaryCalcium: "Calcium",
        .dietaryIron: "Iron",
        .dietaryPotassium: "Potassium",
        .dietaryVitaminA: "Vitamin A",
        .dietaryVitaminB6: "Vitamin B6",
        .dietaryVitaminB12: "Vitamin B12",
        .dietaryVitaminC: "Vitamin C",
        .dietaryVitaminD: "Vitamin D",
        .dietaryVitaminE: "Vitamin E",
        .dietaryVitaminK: "Vitamin K",
        .dietaryBiotin: "Biotin",
        .dietaryThiamin: "Thiamin",
        .dietaryRiboflavin: "Riboflavin",
        .dietaryNiacin: "Niacin",
        .dietaryFolate: "Folate",
        .dietaryPantothenicAcid: "Pantothenic Acid",
        .dietaryPhosphorus: "Phosphorus",
        .dietaryIodine: "Iodine",
        .dietaryMagnesium: "Magnesium",
        .dietaryZinc: "Zinc",
        .dietarySelenium: "Selenium",
        .dietaryCopper: "Copper",
        .dietaryManganese: "Manganese",
        .dietaryChromium: "Chromium",
        .dietaryMolybdenum: "Molybdenum",
        .dietaryChloride: "Chloride",
        .dietaryWater: "Water",
        .dietaryCaffeine: "Caffeine",
        // Respiratory
        .peakExpiratoryFlowRate: "Peak Expiratory Flow",
        .forcedExpiratoryVolume1: "Forced Expiratory Volume",
        .forcedVitalCapacity: "Forced Vital Capacity",
        .inhalerUsage: "Inhaler Usage",
        // Mobility
        .walkingSpeed: "Walking Speed",
        .walkingStepLength: "Walking Step Length",
        .walkingDoubleSupportPercentage: "Double Support Time",
        .walkingAsymmetryPercentage: "Walking Asymmetry",
        .sixMinuteWalkTestDistance: "Six-Minute Walk",
        .stairAscentSpeed: "Stair Ascent Speed",
        .stairDescentSpeed: "Stair Descent Speed",
        .appleWalkingSteadiness: "Walking Steadiness",
        // Fitness
        .vo2Max: "VO2 Max",
        // Audio Exposure
        .environmentalAudioExposure: "Environmental Sound",
        .headphoneAudioExposure: "Headphone Audio",
        // Other
        .uvExposure: "UV Exposure",
        .numberOfTimesFallen: "Number of Falls",
        .timeInDaylight: "Time in Daylight",
        // Sleep & Mindfulness
        .sleepAnalysis: "Sleep",
        .mindfulSession: "Mindful Minutes",
        // Activity Events
        .appleStandHour: "Stand Hours",
        // Heart Events
        .highHeartRateEvent: "High Heart Rate Event",
        .lowHeartRateEvent: "Low Heart Rate Event",
        .irregularHeartRhythmEvent: "Irregular Rhythm Event",
        .lowCardioFitnessEvent: "Low Cardio Fitness Event",
        // Reproductive Health
        .menstrualFlow: "Menstrual Flow",
        .cervicalMucusQuality: "Cervical Mucus Quality",
        .ovulationTestResult: "Ovulation Test",
        .sexualActivity: "Sexual Activity",
        .intermenstrualBleeding: "Intermenstrual Bleeding",
        .contraceptive: "Contraceptive",
        .lactation: "Lactation",
        .pregnancy: "Pregnancy",
        .pregnancyTestResult: "Pregnancy Test",
        .progesteroneTestResult: "Progesterone Test",
        .infrequentMenstrualCycles: "Infrequent Cycles",
        .irregularMenstrualCycles: "Irregular Cycles",
        .prolongedMenstrualPeriods: "Prolonged Periods",
        .persistentIntermenstrualBleeding: "Persistent Spotting",
        // Symptoms
        .abdominalCramps: "Abdominal Cramps",
        .acne: "Acne",
        .appetiteChanges: "Appetite Changes",
        .bladderIncontinence: "Bladder Incontinence",
        .bloating: "Bloating",
        .breastPain: "Breast Pain",
        .chestTightnessOrPain: "Chest Tightness",
        .chills: "Chills",
        .constipation: "Constipation",
        .coughing: "Coughing",
        .diarrhea: "Diarrhea",
        .dizziness: "Dizziness",
        .drySkin: "Dry Skin",
        .fainting: "Fainting",
        .fatigue: "Fatigue",
        .fever: "Fever",
        .generalizedBodyAche: "Body Aches",
        .hairLoss: "Hair Loss",
        .headache: "Headache",
        .heartburn: "Heartburn",
        .hotFlashes: "Hot Flashes",
        .lossOfSmell: "Loss of Smell",
        .lossOfTaste: "Loss of Taste",
        .lowerBackPain: "Lower Back Pain",
        .memoryLapse: "Memory Lapse",
        .moodChanges: "Mood Changes",
        .nausea: "Nausea",
        .nightSweats: "Night Sweats",
        .pelvicPain: "Pelvic Pain",
        .rapidPoundingOrFlutteringHeartbeat: "Rapid Heartbeat",
        .runnyNose: "Runny Nose",
        .shortnessOfBreath: "Shortness of Breath",
        .sinusCongestion: "Sinus Congestion",
        .skippedHeartbeat: "Skipped Heartbeat",
        .sleepChanges: "Sleep Changes",
        .soreThroat: "Sore Throat",
        .vaginalDryness: "Vaginal Dryness",
        .vomiting: "Vomiting",
        .wheezing: "Wheezing",
        // Hygiene
        .toothbrushingEvent: "Toothbrushing",
        .handwashingEvent: "Handwashing",
        // Audio Events
        .environmentalAudioExposureEvent: "Loud Environment Event",
        .headphoneAudioExposureEvent: "Loud Headphone Event",
        // Correlations
        .bloodPressure: "Blood Pressure",
        .food: "Food",
        // Characteristics
        .biologicalSex: "Biological Sex",
        .bloodType: "Blood Type",
        .dateOfBirth: "Date of Birth",
        .fitzpatrickSkinType: "Skin Type",
        .wheelchairUse: "Wheelchair Use",
        .activityMoveMode: "Activity Move Mode",
        // Workout
        .workout: "Workouts",
    ]
}
