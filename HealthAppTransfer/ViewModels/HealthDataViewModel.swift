import Foundation
import SwiftUI

// MARK: - Health Data ViewModel

@MainActor
class HealthDataViewModel: ObservableObject {

    // MARK: - Types

    struct TypeInfo: Identifiable {
        let type: HealthDataType
        let count: Int
        var id: String { type.rawValue }
        var displayName: String { type.displayName }
    }

    struct CategoryGroup: Identifiable {
        let category: HealthDataCategory
        let types: [TypeInfo]
        var id: String { category.rawValue }
        var totalCount: Int { types.reduce(0) { $0 + $1.count } }
    }

    // MARK: - Published State

    @Published var allGroups: [CategoryGroup] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Computed

    var filteredGroups: [CategoryGroup] {
        guard !searchText.isEmpty else { return allGroups }
        let query = searchText.lowercased()
        return allGroups.compactMap { group in
            let matched = group.types.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
            guard !matched.isEmpty else { return nil }
            return CategoryGroup(category: group.category, types: matched)
        }
    }

    var isEmpty: Bool {
        allGroups.allSatisfy { $0.types.isEmpty }
    }

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Data Loading

    func loadDataTypes() async {
        isLoading = true
        defer { isLoading = false }

        let available = await healthKitService.availableTypes()
        let lookup = Dictionary(uniqueKeysWithValues: available.map { ($0.type, $0.count) })

        allGroups = HealthDataType.groupedByCategory.map { group in
            let typeInfos = group.types.map { type in
                TypeInfo(type: type, count: lookup[type] ?? 0)
            }
            return CategoryGroup(category: group.category, types: typeInfos)
        }
    }
}
