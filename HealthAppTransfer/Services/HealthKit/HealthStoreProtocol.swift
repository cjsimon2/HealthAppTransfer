import HealthKit

// MARK: - Health Store Protocol

/// Abstraction over HKHealthStore for testability.
protocol HealthStoreProtocol: Sendable {
    func requestAuthorization(toShare: Set<HKSampleType>?, read: Set<HKObjectType>?) async throws
    func execute(_ query: HKQuery)
    func stop(_ query: HKQuery)
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus

    /// Check if any data exists for the given sample type.
    /// Uses efficient server-side queries (HKStatisticsQuery for quantity types,
    /// limit-1 HKSampleQuery for others) to avoid loading samples into memory.
    func dataExists(for sampleType: HKSampleType) async throws -> Bool
}

// MARK: - HKHealthStore Conformance

extension HKHealthStore: HealthStoreProtocol {
    func requestAuthorization(toShare: Set<HKSampleType>?, read: Set<HKObjectType>?) async throws {
        try await requestAuthorization(toShare: toShare ?? [], read: read ?? [])
    }

    func dataExists(for sampleType: HKSampleType) async throws -> Bool {
        if let quantityType = sampleType as? HKQuantityType {
            return try await quantityDataExists(for: quantityType)
        }
        return try await sampleDataExists(for: sampleType)
    }

    // MARK: - Private Helpers

    /// Use HKStatisticsQuery for quantity types — processed entirely in the HealthKit daemon.
    private func quantityDataExists(for quantityType: HKQuantityType) async throws -> Bool {
        let options: HKStatisticsOptions = quantityType.aggregationStyle == .cumulative
            ? .cumulativeSum
            : .discreteAverage

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: nil,
                options: options
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let hasData = statistics?.sumQuantity() != nil
                        || statistics?.averageQuantity() != nil
                    continuation.resume(returning: hasData)
                }
            }
            self.execute(query)
        }
    }

    /// Use limit-1 HKSampleQuery for non-quantity types (category, workout).
    private func sampleDataExists(for sampleType: HKSampleType) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: nil,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.isEmpty == false)
                }
            }
            self.execute(query)
        }
    }
}
