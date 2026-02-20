import Foundation
import SwiftUI

// MARK: - Health Data ViewModel

@MainActor
class HealthDataViewModel: ObservableObject {

    // MARK: - Published State

    @Published var dataTypes: [(typeName: String, count: Int)] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Data Loading

    func loadDataTypes() async {
        isLoading = true
        defer { isLoading = false }

        let types = await healthKitService.availableTypes()
        dataTypes = types.map { (typeName: $0.type.rawValue, count: $0.count) }
    }
}
