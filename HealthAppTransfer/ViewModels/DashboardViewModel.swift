import Foundation
import SwiftUI

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {

    // MARK: - Types

    struct CategorySummary: Identifiable {
        let category: HealthDataCategory
        let availableCount: Int
        let totalTypes: Int
        var id: String { category.rawValue }
    }

    // MARK: - Published State

    @Published var categories: [CategorySummary] = []
    @Published var totalAvailable = 0
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

        let available = await healthKitService.availableTypes()
        let availableSet = Set(available.map(\.type))

        categories = HealthDataType.groupedByCategory.map { group in
            let availableCount = group.types.filter { availableSet.contains($0) }.count
            return CategorySummary(
                category: group.category,
                availableCount: availableCount,
                totalTypes: group.types.count
            )
        }

        totalAvailable = availableSet.count
    }
}
