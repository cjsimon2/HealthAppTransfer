import CloudKit
import Foundation

// MARK: - CloudKit Record Mapper

/// Maps between HealthSampleDTO and CKRecord for CloudKit sync.
enum CloudKitRecordMapper {

    // MARK: - Constants

    static let recordType = "HealthSample"
    static let zoneName = "HealthData"

    static var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }

    // MARK: - DTO → CKRecord

    /// Converts a HealthSampleDTO to a CKRecord for upload.
    static func record(from dto: HealthSampleDTO) -> CKRecord {
        let recordID = CKRecord.ID(recordName: dto.id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["typeRawValue"] = dto.type.rawValue as NSString
        record["startDate"] = dto.startDate as NSDate
        record["endDate"] = dto.endDate as NSDate
        record["sourceName"] = dto.sourceName as NSString
        record["sourceBundleIdentifier"] = dto.sourceBundleIdentifier as NSString?

        // Quantity
        if let value = dto.value {
            record["value"] = value as NSNumber
        }
        record["unit"] = dto.unit as NSString?

        // Category
        if let categoryValue = dto.categoryValue {
            record["categoryValue"] = categoryValue as NSNumber
        }

        // Workout
        if let workoutActivityType = dto.workoutActivityType {
            record["workoutActivityType"] = Int64(workoutActivityType) as NSNumber
        }
        if let workoutDuration = dto.workoutDuration {
            record["workoutDuration"] = workoutDuration as NSNumber
        }
        if let workoutTotalEnergyBurned = dto.workoutTotalEnergyBurned {
            record["workoutTotalEnergyBurned"] = workoutTotalEnergyBurned as NSNumber
        }
        if let workoutTotalDistance = dto.workoutTotalDistance {
            record["workoutTotalDistance"] = workoutTotalDistance as NSNumber
        }

        // Correlation — encode as JSON string
        if let correlationValues = dto.correlationValues,
           let data = try? JSONEncoder().encode(correlationValues),
           let json = String(data: data, encoding: .utf8) {
            record["correlationValuesJSON"] = json as NSString
        }

        // Characteristic
        record["characteristicValue"] = dto.characteristicValue as NSString?

        // Metadata
        record["metadataJSON"] = dto.metadataJSON as NSString?

        return record
    }

    // MARK: - CKRecord → DTO

    /// Converts a CKRecord back to a HealthSampleDTO for download.
    /// Returns nil if required fields are missing.
    static func dto(from record: CKRecord) -> HealthSampleDTO? {
        guard let idString = record.recordID.recordName as String?,
              let id = UUID(uuidString: idString),
              let typeRawValue = record["typeRawValue"] as? String,
              let type = HealthDataType(rawValue: typeRawValue),
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date,
              let sourceName = record["sourceName"] as? String else {
            return nil
        }

        // Decode correlation values from JSON
        var correlationValues: [String: Double]?
        if let json = record["correlationValuesJSON"] as? String,
           let data = json.data(using: .utf8) {
            correlationValues = try? JSONDecoder().decode([String: Double].self, from: data)
        }

        return HealthSampleDTO(
            id: id,
            type: type,
            startDate: startDate,
            endDate: endDate,
            sourceName: sourceName,
            sourceBundleIdentifier: record["sourceBundleIdentifier"] as? String,
            value: (record["value"] as? NSNumber)?.doubleValue,
            unit: record["unit"] as? String,
            categoryValue: (record["categoryValue"] as? NSNumber)?.intValue,
            workoutActivityType: (record["workoutActivityType"] as? NSNumber).map { UInt($0.int64Value) },
            workoutDuration: (record["workoutDuration"] as? NSNumber)?.doubleValue,
            workoutTotalEnergyBurned: (record["workoutTotalEnergyBurned"] as? NSNumber)?.doubleValue,
            workoutTotalDistance: (record["workoutTotalDistance"] as? NSNumber)?.doubleValue,
            correlationValues: correlationValues,
            characteristicValue: record["characteristicValue"] as? String,
            metadataJSON: record["metadataJSON"] as? String
        )
    }
}
