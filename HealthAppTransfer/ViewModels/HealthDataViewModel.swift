import Foundation
import SwiftData
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

    func loadDataTypes(modelContext: ModelContext? = nil) async {
        #if os(macOS)
        if let modelContext {
            loadDataTypesFromStore(modelContext: modelContext)
            return
        }
        #endif

        await loadDataTypesFromHealthKit()
    }

    // MARK: - HealthKit Path (iOS)

    private func loadDataTypesFromHealthKit() async {
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

    // MARK: - SwiftData Path (macOS)

    #if os(macOS)
    private func loadDataTypesFromStore(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        // Count samples per type from SwiftData
        var typeCounts: [String: Int] = [:]

        for type in HealthDataType.allCases {
            let typeRaw = type.rawValue
            let descriptor = FetchDescriptor<SyncedHealthSample>(
                predicate: #Predicate { $0.typeRawValue == typeRaw }
            )
            let count = (try? modelContext.fetchCount(descriptor)) ?? 0
            if count > 0 {
                typeCounts[typeRaw] = count
            }
        }

        allGroups = HealthDataType.groupedByCategory.map { group in
            let typeInfos = group.types.map { type in
                TypeInfo(type: type, count: typeCounts[type.rawValue] ?? 0)
            }
            return CategoryGroup(category: group.category, types: typeInfos)
        }
    }
    #endif
}
