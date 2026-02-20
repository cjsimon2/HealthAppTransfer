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
                metadataJSON: metadataJSON
            )

        default:
            return nil
        }
    }

    /// Map an array of HKSamples.
    static func map(_ samples: [HKSample], type: HealthDataType) -> [HealthSampleDTO] {
        samples.compactMap { map($0, type: type) }
    }

    // MARK: - Unit Mapping

    /// Returns the preferred HKUnit for a given data type.
    static func preferredUnit(for type: HealthDataType) -> HKUnit {
        switch type {
        case .stepCount, .flightsClimbed:
            return .count()
        case .distanceWalkingRunning:
            return .meter()
        case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed:
            return .kilocalorie()
        case .appleExerciseTime, .appleStandTime:
            return .minute()
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage:
            return HKUnit.count().unitDivided(by: .minute())
        case .heartRateVariabilitySDNN:
            return .secondUnit(with: .milli)
        case .oxygenSaturation, .bodyFatPercentage:
            return .percent()
        case .bodyTemperature:
            return .degreeCelsius()
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return .millimeterOfMercury()
        case .respiratoryRate:
            return HKUnit.count().unitDivided(by: .minute())
        case .bodyMass, .leanBodyMass:
            return .gramUnit(with: .kilo)
        case .bodyMassIndex:
            return .count()
        case .height, .waistCircumference:
            return .meterUnit(with: .centi)
        case .bloodGlucose:
            return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        case .dietaryCarbohydrates, .dietaryFatTotal, .dietaryProtein, .dietaryCaffeine:
            return .gram()
        case .dietaryWater:
            return .literUnit(with: .milli)
        case .environmentalAudioExposure, .headphoneAudioExposure:
            return .decibelAWeightedSoundPressureLevel()
        case .vo2Max:
            return HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        case .sleepAnalysis, .workout:
            fatalError("\(type) does not use HKUnit")
        }
    }

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
