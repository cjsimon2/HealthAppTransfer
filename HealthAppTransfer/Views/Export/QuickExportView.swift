import SwiftUI
import SwiftData

// MARK: - Quick Export View

struct QuickExportView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Observed Objects

    @StateObject private var viewModel: ExportViewModel

    // MARK: - State

    @State private var showTypePicker = false
    @State private var showShareSheet = false

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
        _viewModel = StateObject(wrappedValue: ExportViewModel(healthKitService: healthKitService))
    }

    // MARK: - Body

    var body: some View {
        Form {
            typeSelectionSection
            formatSection
            dateRangeSection
            aggregationSection
            exportSection
        }
        .navigationTitle("Export")
        .task { await viewModel.loadAvailableTypes() }
        .sheet(isPresented: $showTypePicker) {
            typePickerSheet
        }
        .sheet(isPresented: $showShareSheet) {
            if let result = viewModel.exportResult {
                ShareSheetView(fileURL: result.fileURL)
            }
        }
        .alert("Export Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: viewModel.exportResult) { _, newValue in
            if newValue != nil {
                showShareSheet = true
            }
        }
    }

    // MARK: - Type Selection Section

    private var typeSelectionSection: some View {
        Section {
            Button {
                showTypePicker = true
            } label: {
                HStack {
                    Label("Health Data Types", systemImage: "heart.text.square")
                    Spacer()
                    Text(typeCountLabel)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .accessibilityLabel("Select health data types, \(typeCountLabel)")
            .accessibilityIdentifier("export.typeSelection")
        } header: {
            Text("Data")
        } footer: {
            Text("Choose which health data types to include in the export.")
        }
    }

    private var typeCountLabel: String {
        let count = viewModel.selectedTypeCount
        if count == 0 { return "None" }
        return "\(count) selected"
    }

    // MARK: - Format Section

    private var formatSection: some View {
        Section {
            Picker("Format", selection: $viewModel.selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .accessibilityLabel("Export format")
            .accessibilityIdentifier("export.formatPicker")
        } header: {
            Text("Format")
        } footer: {
            formatFooter
        }
    }

    @ViewBuilder
    private var formatFooter: some View {
        switch viewModel.selectedFormat {
        case .jsonV1:
            Text("Flat JSON array of all samples. Compatible with Health Auto Export.")
        case .jsonV2:
            Text("Grouped JSON with metadata header. Includes device info and type grouping.")
        case .csv:
            Text("Comma-separated values. Opens in Excel, Numbers, or any spreadsheet app.")
        case .gpx:
            Text("GPS exchange format for workout routes. Requires workout data.")
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        Section("Date Range") {
            DatePicker("From", selection: $viewModel.startDate, displayedComponents: .date)
                .accessibilityLabel("Start date")
                .accessibilityIdentifier("export.startDate")
            DatePicker("To", selection: $viewModel.endDate, displayedComponents: .date)
                .accessibilityLabel("End date")
                .accessibilityIdentifier("export.endDate")
        }
    }

    // MARK: - Aggregation Section

    private var aggregationSection: some View {
        Section {
            Toggle("Aggregate Data", isOn: $viewModel.aggregationEnabled)
                .accessibilityLabel("Enable data aggregation")
                .accessibilityIdentifier("export.aggregationToggle")

            if viewModel.aggregationEnabled {
                Picker("Interval", selection: $viewModel.aggregationInterval) {
                    ForEach(AggregationInterval.allCases, id: \.self) { interval in
                        Text(interval.rawValue.capitalized).tag(interval)
                    }
                }
                .accessibilityLabel("Aggregation interval")
            }
        } header: {
            Text("Aggregation")
        } footer: {
            if viewModel.aggregationEnabled {
                Text("Data will be summarized per interval instead of exporting individual samples. Only applies to quantity types.")
            }
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Button {
                Task { await viewModel.performExport(modelContext: modelContext) }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isExporting {
                        exportProgressView
                    } else {
                        Label("Export & Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                    }
                    Spacer()
                }
            }
            .disabled(!viewModel.canExport)
            .accessibilityLabel(viewModel.isExporting ? "Exporting data" : "Export and share")
            .accessibilityIdentifier("export.exportButton")
        }
    }

    private var exportProgressView: some View {
        VStack(spacing: 8) {
            ProgressView(value: viewModel.progress?.fraction ?? 0) {
                Text("Exporting...")
                    .font(.headline)
            }
            if let typeName = viewModel.progress?.currentTypeName {
                Text("Fetching \(typeName)...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Type Picker Sheet

    private var typePickerSheet: some View {
        NavigationStack {
            TypePickerView(
                availableTypes: viewModel.availableTypes,
                selectedTypes: $viewModel.selectedTypes,
                isLoading: viewModel.isLoadingTypes,
                onSelectAll: { viewModel.selectAll() },
                onDeselectAll: { viewModel.deselectAll() }
            )
            .navigationTitle("Select Types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showTypePicker = false }
                }
            }
        }
    }
}

// MARK: - Type Picker View

private struct TypePickerView: View {

    let availableTypes: [(category: HealthDataCategory, types: [HealthDataType])]
    @Binding var selectedTypes: Set<HealthDataType>
    let isLoading: Bool
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void

    @State private var searchText = ""

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading available types...")
            } else {
                typeList
            }
        }
        .searchable(text: $searchText, prompt: "Search types")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Select All") { onSelectAll() }
                    Button("Deselect All") { onDeselectAll() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Selection options")
                .accessibilityIdentifier("typePicker.optionsMenu")
            }
        }
    }

    private var filteredTypes: [(category: HealthDataCategory, types: [HealthDataType])] {
        guard !searchText.isEmpty else { return availableTypes }
        let query = searchText.lowercased()
        return availableTypes.compactMap { group in
            let matched = group.types.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
            guard !matched.isEmpty else { return nil }
            return (category: group.category, types: matched)
        }
    }

    private var typeList: some View {
        List {
            ForEach(filteredTypes, id: \.category) { group in
                Section {
                    ForEach(group.types, id: \.self) { type in
                        Button {
                            toggleSelection(type)
                        } label: {
                            HStack {
                                Text(type.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedTypes.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .font(.body.weight(.semibold))
                                }
                            }
                        }
                        .accessibilityLabel("\(type.displayName), \(selectedTypes.contains(type) ? "selected" : "not selected")")
                    }
                } header: {
                    Label(group.category.displayName, systemImage: group.category.iconName)
                }
            }
        }
    }

    private func toggleSelection(_ type: HealthDataType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
}

// MARK: - Share Sheet View

struct ShareSheetView: View {
    let fileURL: URL

    var body: some View {
        #if os(iOS)
        ShareSheetRepresentable(fileURL: fileURL)
            .ignoresSafeArea()
        #else
        macOSSavePanel
        #endif
    }

    #if os(macOS)
    private var macOSSavePanel: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Export Complete")
                .font(.title2.weight(.semibold))

            Text(fileURL.lastPathComponent)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Save to Disk...") {
                showNSSavePanel()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
    }

    private func showNSSavePanel() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileURL.lastPathComponent
        panel.allowedContentTypes = [.data]
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let saveURL = panel.url {
            try? FileManager.default.copyItem(at: fileURL, to: saveURL)
        }
    }
    #endif
}

// MARK: - iOS Share Sheet

#if os(iOS)
import UIKit

struct ShareSheetRepresentable: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

// MARK: - ExportResult Equatable

extension ExportResult: Equatable {
    static func == (lhs: ExportResult, rhs: ExportResult) -> Bool {
        lhs.fileURL == rhs.fileURL
    }
}
