import Foundation

// MARK: - Health Sample DTO

/// A flat, Codable representation of a HealthKit sample suitable for JSON transfer.
struct HealthSampleDTO: Codable, Sendable, Identifiable {
    let id: UUID
    let type: HealthDataType
    let startDate: Date
    let endDate: Date
    let sourceName: String
    let sourceBundleIdentifier: String?

    /// Quantity value (for quantity types).
    let value: Double?

    /// Unit string (e.g. "count", "kcal", "bpm").
    let unit: String?

    /// Category value (for category types like sleep analysis).
    let categoryValue: Int?

    /// Workout-specific fields.
    let workoutActivityType: UInt?
    let workoutDuration: TimeInterval?
    let workoutTotalEnergyBurned: Double?
    let workoutTotalDistance: Double?

    /// Optional metadata dictionary encoded as JSON string.
    let metadataJSON: String?
}

// MARK: - Batch Response

/// A page of health samples for the /health/data endpoint.
struct HealthDataBatch: Codable, Sendable {
    let type: HealthDataType
    let samples: [HealthSampleDTO]
    let totalCount: Int
    let offset: Int
    let limit: Int
    let hasMore: Bool
}
