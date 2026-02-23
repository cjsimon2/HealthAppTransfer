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

// MARK: - SwiftData Aggregation

extension SyncedHealthSample {

    /// Aggregate synced samples by time interval — SwiftData equivalent of AggregationEngine.
    @MainActor
    static func aggregate(
        type: HealthDataType,
        interval: AggregationInterval,
        from startDate: Date,
        to endDate: Date,
        modelContext: ModelContext
    ) -> [AggregatedSample] {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<SyncedHealthSample>(
            predicate: #Predicate { sample in
                sample.typeRawValue == typeRaw &&
                sample.startDate >= startDate &&
                sample.startDate <= endDate
            },
            sortBy: [SortDescriptor(\.startDate)]
        )

        let samples = (try? modelContext.fetch(descriptor)) ?? []

        // Group by interval bucket
        let calendar = Calendar.current
        var groups: [Date: [SyncedHealthSample]] = [:]
        for sample in samples {
            let bucket = Self.bucketStart(for: sample.startDate, interval: interval, calendar: calendar)
            groups[bucket, default: []].append(sample)
        }

        // Generate all buckets in range
        var results: [AggregatedSample] = []
        var current = Self.bucketStart(for: startDate, interval: interval, calendar: calendar)

        while current <= endDate {
            guard let bucketEnd = calendar.date(byAdding: interval.dateComponents, to: current) else { break }
            let bucketSamples = groups[current] ?? []
            let values = bucketSamples.compactMap(\.value)
            let unit = bucketSamples.first?.unit ?? ""

            results.append(AggregatedSample(
                startDate: current,
                endDate: bucketEnd,
                sum: values.isEmpty ? nil : values.reduce(0, +),
                average: values.isEmpty ? nil : values.reduce(0, +) / Double(values.count),
                min: values.min(),
                max: values.max(),
                latest: values.last,
                count: values.isEmpty ? 0 : 1,
                unit: unit
            ))

            current = bucketEnd
        }

        return results
    }

    /// Fetch recent samples as DTOs from SwiftData.
    @MainActor
    static func recentDTOs(
        for type: HealthDataType,
        limit: Int,
        modelContext: ModelContext
    ) -> [HealthSampleDTO] {
        let typeRaw = type.rawValue
        var descriptor = FetchDescriptor<SyncedHealthSample>(
            predicate: #Predicate { $0.typeRawValue == typeRaw },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let samples = (try? modelContext.fetch(descriptor)) ?? []
        return samples.map { $0.toDTO() }
    }

    private static func bucketStart(for date: Date, interval: AggregationInterval, calendar: Calendar) -> Date {
        switch interval {
        case .hourly:
            return calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: date))
                ?? calendar.startOfDay(for: date)
        case .daily:
            return calendar.startOfDay(for: date)
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        case .yearly:
            let components = calendar.dateComponents([.year], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        }
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
