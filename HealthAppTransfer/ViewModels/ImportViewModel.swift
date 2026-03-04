import Foundation
import SwiftUI
import SwiftData

// MARK: - Import ViewModel

@MainActor
class ImportViewModel: ObservableObject {

    // MARK: - Published State

    @Published var parsedSamples: [HealthSampleDTO] = []
    @Published var detectedFormat: String?
    @Published var isParsing = false
    @Published var isImporting = false
    @Published var error: Error?
    @Published var importedCount: Int?

    // MARK: - Dependencies

    private let parserService: ImportParserService

    init(parserService: ImportParserService = ImportParserService()) {
        self.parserService = parserService
    }

    // MARK: - Computed

    var sampleCount: Int { parsedSamples.count }

    var typeBreakdown: [(type: HealthDataType, count: Int)] {
        var counts: [HealthDataType: Int] = [:]
        for sample in parsedSamples {
            counts[sample.type, default: 0] += 1
        }
        return counts.sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (type: $0.key, count: $0.value) }
    }

    var hasParsedData: Bool { !parsedSamples.isEmpty }

    // MARK: - Parse

    func parseFile(url: URL) async {
        isParsing = true
        error = nil
        parsedSamples = []
        detectedFormat = nil
        importedCount = nil

        defer { isParsing = false }

        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let samples = try await parserService.parseFile(at: url)
            parsedSamples = samples
            detectedFormat = url.pathExtension.lowercased() == "json" ? "JSON" : "CSV"
        } catch {
            self.error = error
        }
    }

    // MARK: - Import

    func performImport(modelContext: ModelContext) async {
        guard hasParsedData else { return }

        isImporting = true
        error = nil

        defer { isImporting = false }

        SyncedHealthSample.storeBatch(parsedSamples, syncSource: "import", modelContext: modelContext)
        importedCount = parsedSamples.count
    }
}
