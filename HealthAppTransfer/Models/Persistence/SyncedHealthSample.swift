import Foundation
import SwiftData

// MARK: - Synced Health Sample

/// Persisted health sample received via CloudKit or LAN sync.
/// On macOS (where HealthKit is unavailable), this is the primary data store.
/// On iOS, serves as a cache of synced data.
@Model
final class SyncedHealthSample {

    // MARK: - Identity

    /// Unique sample ID matching the original HealthKit sample UUID.
    @Attribute(.unique) var sampleID: UUID

    // MARK: - Core Fields

    /// Raw value of HealthDataType enum.
    var typeRawValue: String

    var startDate: Date
    var endDate: Date
    var sourceName: String
    var sourceBundleIdentifier: String?

    // MARK: - Quantity

    var value: Double?
    var unit: String?

    // MARK: - Category

    var categoryValue: Int?

    // MARK: - Workout

    var workoutActivityType: Int?
    var workoutDuration: Double?
    var workoutTotalEnergyBurned: Double?
    var workoutTotalDistance: Double?

    // MARK: - Correlation & Characteristic

    /// JSON-encoded [String: Double] for correlation sub-values.
    var correlationValuesJSON: String?

    var characteristicValue: String?

    // MARK: - Metadata

    var metadataJSON: String?

    // MARK: - Sync Info

    var syncedAt: Date

    /// Source of the sync: "cloudkit" or "lan".
    var syncSource: String

    // MARK: - Init

    init(
        sampleID: UUID,
        typeRawValue: String,
        startDate: Date,
        endDate: Date,
        sourceName: String,
        sourceBundleIdentifier: String? = nil,
        value: Double? = nil,
        unit: String? = nil,
        categoryValue: Int? = nil,
        workoutActivityType: Int? = nil,
        workoutDuration: Double? = nil,
        workoutTotalEnergyBurned: Double? = nil,
        workoutTotalDistance: Double? = nil,
        correlationValuesJSON: String? = nil,
        characteristicValue: String? = nil,
        metadataJSON: String? = nil,
        syncSource: String
    ) {
        self.sampleID = sampleID
        self.typeRawValue = typeRawValue
        self.startDate = startDate
        self.endDate = endDate
        self.sourceName = sourceName
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.value = value
        self.unit = unit
        self.categoryValue = categoryValue
        self.workoutActivityType = workoutActivityType
        self.workoutDuration = workoutDuration
        self.workoutTotalEnergyBurned = workoutTotalEnergyBurned
        self.workoutTotalDistance = workoutTotalDistance
        self.correlationValuesJSON = correlationValuesJSON
        self.characteristicValue = characteristicValue
        self.metadataJSON = metadataJSON
        self.syncedAt = Date()
        self.syncSource = syncSource
    }

    // MARK: - DTO Conversion

    /// Create from a HealthSampleDTO received via sync.
    init(from dto: HealthSampleDTO, syncSource: String) {
        var corrJSON: String?
        if let correlationValues = dto.correlationValues,
           let data = try? JSONEncoder().encode(correlationValues),
           let json = String(data: data, encoding: .utf8) {
            corrJSON = json
        }

        self.sampleID = dto.id
        self.typeRawValue = dto.type.rawValue
        self.startDate = dto.startDate
        self.endDate = dto.endDate
        self.sourceName = dto.sourceName
        self.sourceBundleIdentifier = dto.sourceBundleIdentifier
        self.value = dto.value
        self.unit = dto.unit
        self.categoryValue = dto.categoryValue
        self.workoutActivityType = dto.workoutActivityType.map { Int($0) }
        self.workoutDuration = dto.workoutDuration
        self.workoutTotalEnergyBurned = dto.workoutTotalEnergyBurned
        self.workoutTotalDistance = dto.workoutTotalDistance
        self.correlationValuesJSON = corrJSON
        self.characteristicValue = dto.characteristicValue
        self.metadataJSON = dto.metadataJSON
        self.syncedAt = Date()
        self.syncSource = syncSource
    }

    /// Convert back to a HealthSampleDTO for export or display.
    func toDTO() -> HealthSampleDTO {
        var correlationValues: [String: Double]?
        if let json = correlationValuesJSON,
           let data = json.data(using: .utf8) {
            correlationValues = try? JSONDecoder().decode([String: Double].self, from: data)
        }

        return HealthSampleDTO(
            id: sampleID,
            type: HealthDataType(rawValue: typeRawValue) ?? .stepCount,
            startDate: startDate,
            endDate: endDate,
            sourceName: sourceName,
            sourceBundleIdentifier: sourceBundleIdentifier,
            value: value,
            unit: unit,
            categoryValue: categoryValue,
            workoutActivityType: workoutActivityType.map { UInt($0) },
            workoutDuration: workoutDuration,
            workoutTotalEnergyBurned: workoutTotalEnergyBurned,
            workoutTotalDistance: workoutTotalDistance,
            correlationValues: correlationValues,
            characteristicValue: characteristicValue,
            metadataJSON: metadataJSON
        )
    }
}

// MARK: - Batch Storage

extension SyncedHealthSample {

    /// Store an array of DTOs in SwiftData, skipping duplicates by sampleID.
    @MainActor
    static func storeBatch(_ dtos: [HealthSampleDTO], syncSource: String, modelContext: ModelContext) {
        for dto in dtos {
            let id = dto.id
            let descriptor = FetchDescriptor<SyncedHealthSample>(
                predicate: #Predicate { $0.sampleID == id }
            )
            if (try? modelContext.fetchCount(descriptor)) ?? 0 == 0 {
                modelContext.insert(SyncedHealthSample(from: dto, syncSource: syncSource))
            }
        }
        try? modelContext.save()
    }
}
