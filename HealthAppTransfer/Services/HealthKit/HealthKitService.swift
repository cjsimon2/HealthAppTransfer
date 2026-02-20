import Foundation
import HealthKit

// MARK: - HealthKit Service

/// Actor managing all HealthKit data access. Reads the 34 supported health data types.
actor HealthKitService {

    // MARK: - Properties

    private let store: any HealthStoreProtocol
    private var isAuthorized = false

    init(store: any HealthStoreProtocol = HKHealthStore()) {
        self.store = store
    }

    // MARK: - Authorization

    /// Request read authorization for all supported health data types.
    func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = Set(HealthDataType.allCases.map { $0.sampleType as HKObjectType })
        try await store.requestAuthorization(toShare: nil, read: readTypes)
        isAuthorized = true
        Loggers.healthKit.info("HealthKit authorization granted for \(HealthDataType.allCases.count) types")
    }

    /// Check if HealthKit is available on this device.
    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Querying

    /// Fetch samples for a specific health data type within a date range.
    func fetchSamples(
        for type: HealthDataType,
        from startDate: Date? = nil,
        to endDate: Date? = nil,
        limit: Int = HKObjectQueryNoLimit
    ) async throws -> [HKSample] {
        let sampleType = type.sampleType

        var predicates: [NSPredicate] = []
        if let startDate {
            predicates.append(HKQuery.predicateForSamples(withStart: startDate, end: nil))
        }
        if let endDate {
            predicates.append(HKQuery.predicateForSamples(withStart: nil, end: endDate))
        }

        let predicate: NSPredicate? = predicates.isEmpty ? nil :
            NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            store.execute(query)
        }
    }

    /// Fetch samples as DTOs ready for JSON transfer.
    func fetchSampleDTOs(
        for type: HealthDataType,
        from startDate: Date? = nil,
        to endDate: Date? = nil,
        limit: Int = HKObjectQueryNoLimit
    ) async throws -> [HealthSampleDTO] {
        let samples = try await fetchSamples(for: type, from: startDate, to: endDate, limit: limit)
        return HealthSampleMapper.map(samples, type: type)
    }

    /// Fetch a batch of samples with pagination support.
    func fetchBatch(
        for type: HealthDataType,
        offset: Int = 0,
        limit: Int = 500,
        from startDate: Date? = nil,
        to endDate: Date? = nil
    ) async throws -> HealthDataBatch {
        // Fetch limit + 1 to check if there are more
        let allSamples = try await fetchSamples(
            for: type,
            from: startDate,
            to: endDate,
            limit: offset + limit + 1
        )

        let hasMore = allSamples.count > offset + limit
        let pageEnd = min(offset + limit, allSamples.count)
        let pageSamples = offset < allSamples.count ? Array(allSamples[offset..<pageEnd]) : []
        let dtos = HealthSampleMapper.map(pageSamples, type: type)

        return HealthDataBatch(
            type: type,
            samples: dtos,
            totalCount: allSamples.count - (hasMore ? 1 : 0),
            offset: offset,
            limit: limit,
            hasMore: hasMore
        )
    }

    /// Count samples for a specific type.
    func sampleCount(for type: HealthDataType) async throws -> Int {
        let sampleType = type.sampleType

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.count ?? 0)
                }
            }
            store.execute(query)
        }
    }

    /// Get available types with their sample counts.
    func availableTypes() async -> [(type: HealthDataType, count: Int)] {
        var results: [(type: HealthDataType, count: Int)] = []

        for dataType in HealthDataType.allCases {
            do {
                let count = try await sampleCount(for: dataType)
                if count > 0 {
                    results.append((type: dataType, count: count))
                }
            } catch {
                Loggers.healthKit.warning("Failed to count \(dataType.rawValue): \(error.localizedDescription)")
            }
        }

        return results
    }
}
