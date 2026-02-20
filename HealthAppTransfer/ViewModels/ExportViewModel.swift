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

    func loadAvailableTypes() async {
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

        do {
            let result = try await exportService.export(
                types: Array(selectedTypes).sorted(by: { $0.rawValue < $1.rawValue }),
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
}
