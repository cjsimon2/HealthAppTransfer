import HealthKit

// MARK: - Health Store Protocol

/// Abstraction over HKHealthStore for testability.
protocol HealthStoreProtocol: Sendable {
    func requestAuthorization(toShare: Set<HKSampleType>?, read: Set<HKObjectType>?) async throws
    func execute(_ query: HKQuery)
    func stop(_ query: HKQuery)
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
}

// MARK: - HKHealthStore Conformance

extension HKHealthStore: HealthStoreProtocol {
    func requestAuthorization(toShare: Set<HKSampleType>?, read: Set<HKObjectType>?) async throws {
        try await requestAuthorization(toShare: toShare ?? [], read: read ?? [])
    }
}
