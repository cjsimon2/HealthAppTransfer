import Foundation
import SwiftUI

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {

    // MARK: - Published State

    @Published var availableTypes: [(typeName: String, count: Int)] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Data Loading

    func loadOverview() async {
        isLoading = true
        defer { isLoading = false }

        let types = await healthKitService.availableTypes()
        availableTypes = types.map { (typeName: $0.type.rawValue, count: $0.count) }
    }
}
