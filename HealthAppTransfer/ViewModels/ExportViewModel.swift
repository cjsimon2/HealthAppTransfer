import Foundation
import SwiftUI
import SwiftData

// MARK: - Export ViewModel

@MainActor
class ExportViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedTypes: Set<HealthDataType> = []
    @Published var selectedFormat: ExportFormat = .jsonV2
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Published var endDate: Date = Date()
    @Published var aggregationEnabled = false
    @Published var aggregationInterval: AggregationInterval = .daily

    @Published var isExporting = false
    @Published var progress: ExportProgress?
    @Published var error: Error?
    @Published var exportResult: ExportResult?

    @Published var availableTypes: [(category: HealthDataCategory, types: [HealthDataType])] = []
    @Published var isLoadingTypes = false

    // MARK: - Dependencies

    private let exportService: ExportService
    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
        self.exportService = ExportService(healthKitService: healthKitService)
    }

    // MARK: - Computed

    var canExport: Bool {
        !selectedTypes.isEmpty && !isExporting
    }

    var selectedTypeCount: Int {
        selectedTypes.count
    }

    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }

    // MARK: - Load Available Types

    func loadAvailableTypes(modelContext: ModelContext? = nil) async {
        #if os(macOS)
        if let modelContext {
            loadAvailableTypesFromStore(modelContext: modelContext)
            return
        }
        #endif

        await loadAvailableTypesFromHealthKit()
    }

    private func loadAvailableTypesFromHealthKit() async {
        isLoadingTypes = true
        defer { isLoadingTypes = false }

        let available = await healthKitService.availableTypes()
        let availableSet = Set(available.map(\.type))

        // Group by category, only include types that have data
        availableTypes = HealthDataType.groupedByCategory.compactMap { group in
            let typesWithData = group.types.filter { availableSet.contains($0) }
            guard !typesWithData.isEmpty else { return nil }
            return (category: group.category, types: typesWithData)
        }
    }

    #if os(macOS)
    private func loadAvailableTypesFromStore(modelContext: ModelContext) {
        isLoadingTypes = true
        defer { isLoadingTypes = false }

        // Find types that have synced data
        var typesWithData: Set<HealthDataType> = []
        for type in HealthDataType.allCases {
            let typeRaw = type.rawValue
            let descriptor = FetchDescriptor<SyncedHealthSample>(
                predicate: #Predicate { $0.typeRawValue == typeRaw }
            )
            if (try? modelContext.fetchCount(descriptor)) ?? 0 > 0 {
                typesWithData.insert(type)
            }
        }

        availableTypes = HealthDataType.groupedByCategory.compactMap { group in
            let matched = group.types.filter { typesWithData.contains($0) }
            guard !matched.isEmpty else { return nil }
            return (category: group.category, types: matched)
        }
    }
    #endif

    // MARK: - Type Selection

    func toggleType(_ type: HealthDataType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }

    func selectAll() {
        for group in availableTypes {
            for type in group.types {
                selectedTypes.insert(type)
            }
        }
    }

    func deselectAll() {
        selectedTypes.removeAll()
    }

    // MARK: - Export

    func performExport(modelContext: ModelContext) async {
        guard canExport else { return }

        isExporting = true
        progress = ExportProgress(completedTypes: 0, totalTypes: selectedTypes.count, currentTypeName: nil)
        error = nil
        exportResult = nil

        let sortedTypes = Array(selectedTypes).sorted(by: { $0.rawValue < $1.rawValue })

        do {
            #if os(macOS)
            let result = try await exportFromStore(types: sortedTypes, modelContext: modelContext)
            #else
            let result = try await exportFromHealthKit(types: sortedTypes)
            #endif

            exportResult = result

            // Record the export in SwiftData
            let record = ExportRecord(
                format: selectedFormat.rawValue,
                destination: "file",
                sampleCount: result.sampleCount,
                exportedTypeRawValues: result.exportedTypes.map(\.rawValue),
                succeeded: true
            )
            record.dataStartDate = startDate
            record.dataEndDate = endDate
            record.fileSizeBytes = result.fileSizeBytes
            modelContext.insert(record)
            try? modelContext.save()

        } catch {
            self.error = error

            // Record failed export
            let record = ExportRecord(
                format: selectedFormat.rawValue,
                destination: "file",
                sampleCount: 0,
                exportedTypeRawValues: Array(selectedTypes).map(\.rawValue),
                succeeded: false
            )
            record.errorMessage = error.localizedDescription
            modelContext.insert(record)
            try? modelContext.save()
        }

        isExporting = false
        progress = nil
    }

    // MARK: - HealthKit Export Path (iOS)

    private func exportFromHealthKit(types: [HealthDataType]) async throws -> ExportResult {
        try await exportService.export(
            types: types,
            format: selectedFormat,
            startDate: startDate,
            endDate: endDate,
            aggregationEnabled: aggregationEnabled,
            aggregationInterval: aggregationInterval,
            progressHandler: { [weak self] progress in
                Task { @MainActor in
                    self?.progress = progress
                }
            }
        )
    }

    // MARK: - SwiftData Export Path (macOS)

    #if os(macOS)
    private func exportFromStore(types: [HealthDataType], modelContext: ModelContext) async throws -> ExportResult {
        var allSamples: [HealthSampleDTO] = []
        let start = startDate
        let end = endDate

        for (index, type) in types.enumerated() {
            progress = ExportProgress(
                completedTypes: index,
                totalTypes: types.count,
                currentTypeName: type.displayName
            )

            let typeRaw = type.rawValue
            let descriptor = FetchDescriptor<SyncedHealthSample>(
                predicate: #Predicate { sample in
                    sample.typeRawValue == typeRaw &&
                    sample.startDate >= start &&
                    sample.startDate <= end
                },
                sortBy: [SortDescriptor(\.startDate)]
            )

            if let samples = try? modelContext.fetch(descriptor) {
                allSamples.append(contentsOf: samples.map { $0.toDTO() })
            }
        }

        progress = ExportProgress(completedTypes: types.count, totalTypes: types.count, currentTypeName: nil)

        return try await exportService.exportFromSamples(
            samples: allSamples,
            format: selectedFormat,
            types: types
        )
    }
    #endif
}
