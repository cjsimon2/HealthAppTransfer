import HealthKit

// MARK: - Health Data Type

/// All 34 HealthKit data types supported for transfer.
enum HealthDataType: String, CaseIterable, Codable, Sendable {

    // MARK: - Activity
    case stepCount
    case distanceWalkingRunning
    case flightsClimbed
    case activeEnergyBurned
    case basalEnergyBurned
    case appleExerciseTime
    case appleStandTime

    // MARK: - Heart
    case heartRate
    case restingHeartRate
    case walkingHeartRateAverage
    case heartRateVariabilitySDNN

    // MARK: - Vitals
    case oxygenSaturation
    case bodyTemperature
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case respiratoryRate

    // MARK: - Body Measurements
    case bodyMass
    case bodyMassIndex
    case bodyFatPercentage
    case leanBodyMass
    case height
    case waistCircumference

    // MARK: - Metabolic
    case bloodGlucose

    // MARK: - Nutrition
    case dietaryEnergyConsumed
    case dietaryCarbohydrates
    case dietaryFatTotal
    case dietaryProtein
    case dietaryWater
    case dietaryCaffeine

    // MARK: - Audio Exposure
    case environmentalAudioExposure
    case headphoneAudioExposure

    // MARK: - Fitness
    case vo2Max

    // MARK: - Sleep
    case sleepAnalysis

    // MARK: - Workouts
    case workout

    // MARK: - HealthKit Mapping

    /// The corresponding `HKSampleType` for reading from HealthKit.
    var sampleType: HKSampleType {
        switch self {
        case .sleepAnalysis:
            return HKCategoryType(.sleepAnalysis)
        case .workout:
            return HKWorkoutType.workoutType()
        default:
            return HKQuantityType(quantityTypeIdentifier)
        }
    }

    /// The corresponding `HKQuantityTypeIdentifier` for quantity types.
    /// Fatal error if called on non-quantity types.
    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .stepCount: return .stepCount
        case .distanceWalkingRunning: return .distanceWalkingRunning
        case .flightsClimbed: return .flightsClimbed
        case .activeEnergyBurned: return .activeEnergyBurned
        case .basalEnergyBurned: return .basalEnergyBurned
        case .appleExerciseTime: return .appleExerciseTime
        case .appleStandTime: return .appleStandTime
        case .heartRate: return .heartRate
        case .restingHeartRate: return .restingHeartRate
        case .walkingHeartRateAverage: return .walkingHeartRateAverage
        case .heartRateVariabilitySDNN: return .heartRateVariabilitySDNN
        case .oxygenSaturation: return .oxygenSaturation
        case .bodyTemperature: return .bodyTemperature
        case .bloodPressureSystolic: return .bloodPressureSystolic
        case .bloodPressureDiastolic: return .bloodPressureDiastolic
        case .respiratoryRate: return .respiratoryRate
        case .bodyMass: return .bodyMass
        case .bodyMassIndex: return .bodyMassIndex
        case .bodyFatPercentage: return .bodyFatPercentage
        case .leanBodyMass: return .leanBodyMass
        case .height: return .height
        case .waistCircumference: return .waistCircumference
        case .bloodGlucose: return .bloodGlucose
        case .dietaryEnergyConsumed: return .dietaryEnergyConsumed
        case .dietaryCarbohydrates: return .dietaryCarbohydrates
        case .dietaryFatTotal: return .dietaryFatTotal
        case .dietaryProtein: return .dietaryProtein
        case .dietaryWater: return .dietaryWater
        case .dietaryCaffeine: return .dietaryCaffeine
        case .environmentalAudioExposure: return .environmentalAudioExposure
        case .headphoneAudioExposure: return .headphoneAudioExposure
        case .vo2Max: return .vo2Max
        case .sleepAnalysis, .workout:
            fatalError("\(self) is not a quantity type")
        }
    }

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .stepCount: return "Step Count"
        case .distanceWalkingRunning: return "Walking + Running Distance"
        case .flightsClimbed: return "Flights Climbed"
        case .activeEnergyBurned: return "Active Energy"
        case .basalEnergyBurned: return "Resting Energy"
        case .appleExerciseTime: return "Exercise Minutes"
        case .appleStandTime: return "Stand Minutes"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .walkingHeartRateAverage: return "Walking Heart Rate"
        case .heartRateVariabilitySDNN: return "Heart Rate Variability"
        case .oxygenSaturation: return "Blood Oxygen"
        case .bodyTemperature: return "Body Temperature"
        case .bloodPressureSystolic: return "Blood Pressure (Systolic)"
        case .bloodPressureDiastolic: return "Blood Pressure (Diastolic)"
        case .respiratoryRate: return "Respiratory Rate"
        case .bodyMass: return "Weight"
        case .bodyMassIndex: return "BMI"
        case .bodyFatPercentage: return "Body Fat"
        case .leanBodyMass: return "Lean Body Mass"
        case .height: return "Height"
        case .waistCircumference: return "Waist Circumference"
        case .bloodGlucose: return "Blood Glucose"
        case .dietaryEnergyConsumed: return "Dietary Energy"
        case .dietaryCarbohydrates: return "Carbohydrates"
        case .dietaryFatTotal: return "Total Fat"
        case .dietaryProtein: return "Protein"
        case .dietaryWater: return "Water"
        case .dietaryCaffeine: return "Caffeine"
        case .environmentalAudioExposure: return "Environmental Sound"
        case .headphoneAudioExposure: return "Headphone Audio"
        case .vo2Max: return "VO2 Max"
        case .sleepAnalysis: return "Sleep"
        case .workout: return "Workouts"
        }
    }

    /// Whether this is a quantity type (vs. category or workout).
    var isQuantityType: Bool {
        switch self {
        case .sleepAnalysis, .workout: return false
        default: return true
        }
    }

    /// All sample types as a Set for HealthKit authorization requests.
    static var allSampleTypes: Set<HKSampleType> {
        Set(allCases.map(\.sampleType))
    }
}
