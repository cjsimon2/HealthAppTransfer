import SwiftData
import SwiftUI

// MARK: - Cloud Storage Form View

/// Form for creating or editing an iCloud Drive export automation.
struct CloudStorageFormView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var name: String
    @State private var exportFormat: String
    @State private var incrementalOnly: Bool
    @State private var enabledTypes: Set<String>
    @State private var showingTypePicker = false
    @State private var iCloudAvailable: Bool = true

    /// Existing configuration to edit, or nil when creating new.
    private let existing: AutomationConfiguration?

    // MARK: - Init

    init(configuration: AutomationConfiguration? = nil) {
        self.existing = configuration
        _name = State(initialValue: configuration?.name ?? "")
        _exportFormat = State(initialValue: configuration?.exportFormat ?? "json_v2")
        _incrementalOnly = State(initialValue: configuration?.incrementalOnly ?? true)
        _enabledTypes = State(initialValue: Set(configuration?.enabledTypeRawValues ?? []))
    }

    // MARK: - Body

    var body: some View {
        Form {
            generalSection
            formatSection
            dataTypesSection
            iCloudStatusSection
        }
        .navigationTitle(existing == nil ? "New iCloud Export" : "Edit iCloud Export")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
            if existing == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingTypePicker) {
            typePickerSheet
        }
        .onAppear {
            iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        Section("General") {
            TextField("Name", text: $name)

            Toggle("Export only new data", isOn: $incrementalOnly)
        }
    }

    private var formatSection: some View {
        Section {
            Picker("Format", selection: $exportFormat) {
                Text("JSON v2 (grouped)").tag("json_v2")
                Text("JSON v1 (flat)").tag("json_v1")
                Text("CSV").tag("csv")
            }
        } header: {
            Text("Export Format")
        } footer: {
            Text("Files are saved to iCloud Drive under HealthExports/YYYY-MM-DD/")
        }
    }

    private var dataTypesSection: some View {
        Section {
            Button {
                showingTypePicker = true
            } label: {
                HStack {
                    Text("Health Data Types")
                    Spacer()
                    Text("\(enabledTypes.count) selected")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var iCloudStatusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: iCloudAvailable ? "checkmark.icloud" : "xmark.icloud")
                    .foregroundStyle(iCloudAvailable ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(iCloudAvailable ? "iCloud Drive Available" : "iCloud Drive Unavailable")
                        .font(.body.weight(.medium))

                    if !iCloudAvailable {
                        Text("Sign in to iCloud in Settings to enable cloud exports.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Type Picker

    private var typePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(HealthDataType.groupedByCategory, id: \.category) { group in
                    Section(group.category.displayName) {
                        ForEach(group.types, id: \.rawValue) { type in
                            Button {
                                toggleType(type)
                            } label: {
                                HStack {
                                    Text(type.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if enabledTypes.contains(type.rawValue) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Types")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingTypePicker = false }
                }
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !enabledTypes.isEmpty
    }

    // MARK: - Actions

    private func toggleType(_ type: HealthDataType) {
        if enabledTypes.contains(type.rawValue) {
            enabledTypes.remove(type.rawValue)
        } else {
            enabledTypes.insert(type.rawValue)
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let config = existing {
            config.name = trimmedName
            config.exportFormat = exportFormat
            config.incrementalOnly = incrementalOnly
            config.enabledTypeRawValues = Array(enabledTypes)
            config.updatedAt = Date()
        } else {
            let config = AutomationConfiguration(
                name: trimmedName,
                automationType: "cloud_storage",
                exportFormat: exportFormat
            )
            config.incrementalOnly = incrementalOnly
            config.enabledTypeRawValues = Array(enabledTypes)
            modelContext.insert(config)
        }

        try? modelContext.save()
        dismiss()
    }
}
