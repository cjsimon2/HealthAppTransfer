import CoreLocation
import Foundation
import HealthKit

// MARK: - HealthKit Service

/// Actor managing all HealthKit data access. Reads 180+ supported health data types.
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
        let readTypes = HealthDataType.allObjectTypes
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

    /// Check if data exists for a specific type.
    /// Returns 0 (no data) or 1 (has data). Uses efficient server-side queries
    /// (HKStatisticsQuery for quantity types, limit-1 query for others)
    /// instead of fetching all samples into memory.
    /// Characteristic types always return 0 (not sample-based).
    func sampleCount(for type: HealthDataType) async throws -> Int {
        guard type.isSampleBased else { return 0 }
        return try await store.dataExists(for: type.sampleType) ? 1 : 0
    }

    // MARK: - Workout Routes

    /// Fetch workout route objects associated with a workout.
    func fetchWorkoutRoutes(for workout: HKWorkout) async throws -> [HKWorkoutRoute] {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let routes = (samples as? [HKWorkoutRoute]) ?? []
                    continuation.resume(returning: routes)
                }
            }
            store.execute(query)
        }
    }

    /// Fetch all CLLocations from an HKWorkoutRoute.
    func fetchRouteLocations(from route: HKWorkoutRoute) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { continuation in
            var allLocations: [CLLocation] = []
            var resumed = false

            let query = HKWorkoutRouteQuery(route: route) { _, newLocations, done, error in
                guard !resumed else { return }

                if let error {
                    resumed = true
                    continuation.resume(throwing: error)
                    return
                }

                if let newLocations {
                    allLocations.append(contentsOf: newLocations)
                }

                if done {
                    resumed = true
                    continuation.resume(returning: allLocations)
                }
            }
            store.execute(query)
        }
    }

    /// Fetch heart rate samples for a workout's time range.
    /// Returns samples sorted by start date ascending for efficient timestamp correlation.
    func fetchHeartRateSamples(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let quantitySamples = (samples as? [HKQuantitySample]) ?? []
                    continuation.resume(returning: quantitySamples)
                }
            }
            store.execute(query)
        }
    }

    /// Get available types with their sample counts.
    /// Uses TaskGroup for parallel HealthKit queries — ~10x faster than sequential with 180+ types.
    /// Skips characteristic types (not sample-based).
    func availableTypes() async -> [(type: HealthDataType, count: Int)] {
        let store = self.store

        return await withTaskGroup(
            of: (HealthDataType, Int)?.self,
            returning: [(type: HealthDataType, count: Int)].self
        ) { group in
            for dataType in HealthDataType.allCases where dataType.isSampleBased {
                group.addTask {
                    do {
                        let exists = try await store.dataExists(for: dataType.sampleType)
                        return exists ? (dataType, 1) : nil
                    } catch {
                        Loggers.healthKit.warning("Failed to check \(dataType.rawValue): \(error.localizedDescription)")
                        return nil
                    }
                }
            }

            var results: [(type: HealthDataType, count: Int)] = []
            for await result in group {
                if let result {
                    results.append((type: result.0, count: result.1))
                }
            }

            // Sort alphabetically for consistent ordering regardless of query completion order
            return results.sorted { $0.type.rawValue < $1.type.rawValue }
        }
    }
}
