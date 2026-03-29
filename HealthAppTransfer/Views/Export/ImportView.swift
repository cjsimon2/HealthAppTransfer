import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Import View

/// Allows users to import previously exported health data files (JSON or CSV)
/// back into the app's local SwiftData store.
struct ImportView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @StateObject private var viewModel = ImportViewModel()
    @State private var showFilePicker = false

    // MARK: - Body

    var body: some View {
        Form {
            fileSelectionSection
            if viewModel.hasParsedData {
                previewSection
                importSection
            }
            if let count = viewModel.importedCount {
                resultSection(count: count)
            }
        }
        .navigationTitle("Import Data")
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.json, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Import Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - File Selection

    private var fileSelectionSection: some View {
        Section {
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Label("Select File", systemImage: "doc.badge.plus")
                    Spacer()
                    if viewModel.isParsing {
                        ProgressView()
                    } else if let format = viewModel.detectedFormat {
                        Text(format)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityLabel("Select file to import")
            .accessibilityIdentifier("import.selectFile")
        } header: {
            Text("File")
        } footer: {
            Text("Select a .json or .csv file exported from this app.")
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        Section {
            LabeledContent("Samples", value: "\(viewModel.sampleCount)")
                .accessibilityIdentifier("import.sampleCount")

            ForEach(viewModel.typeBreakdown, id: \.type) { item in
                LabeledContent(item.type.displayName, value: "\(item.count)")
            }
        } header: {
            Text("Preview")
        } footer: {
            Text("These samples will be added to your local data store. Duplicates are skipped automatically.")
        }
    }

    // MARK: - Import Action

    private var importSection: some View {
        Section {
            Button {
                Task { await viewModel.performImport(modelContext: modelContext) }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isImporting {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Importing...")
                            .font(.headline)
                    } else {
                        Label("Import \(viewModel.sampleCount) Samples", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.accentColor)
            .disabled(viewModel.isImporting)
            .accessibilityLabel("Import \(viewModel.sampleCount) samples")
            .accessibilityIdentifier("import.importButton")
        }
    }

    // MARK: - Result

    private func resultSection(count: Int) -> some View {
        Section {
            Label("Successfully imported \(count) samples", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityIdentifier("import.successLabel")
        }
    }

    // MARK: - Helpers

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task { await viewModel.parseFile(url: url) }
        case .failure(let error):
            viewModel.error = error
        }
    }
}
