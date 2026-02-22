import SwiftData
import SwiftUI

// MARK: - REST Automation Form View

/// Form for creating or editing a REST API automation configuration.
struct RESTAutomationFormView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var name: String
    @State private var endpoint: String
    @State private var exportFormat: String
    @State private var incrementalOnly: Bool
    @State private var headers: [HeaderEntry]
    @State private var enabledTypes: Set<String>
    @State private var showingTypePicker = false

    /// Existing configuration to edit, or nil when creating new.
    private let existing: AutomationConfiguration?

    // MARK: - Init

    init(configuration: AutomationConfiguration? = nil) {
        self.existing = configuration
        _name = State(initialValue: configuration?.name ?? "")
        _endpoint = State(initialValue: configuration?.endpoint ?? "")
        _exportFormat = State(initialValue: configuration?.exportFormat ?? "json_v2")
        _incrementalOnly = State(initialValue: configuration?.incrementalOnly ?? true)
        _enabledTypes = State(initialValue: Set(configuration?.enabledTypeRawValues ?? []))

        // Parse existing headers into editable entries
        let existingHeaders = configuration?.httpHeaders ?? [:]
        let entries = existingHeaders.map { HeaderEntry(key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }
        _headers = State(initialValue: entries.isEmpty ? [HeaderEntry()] : entries)
    }

    // MARK: - Body

    var body: some View {
        Form {
            basicSection
            headersSection
            payloadSection
            dataTypesSection
        }
        .navigationTitle(existing == nil ? "New REST Automation" : "Edit Automation")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
                    .accessibilityIdentifier("restForm.saveButton")
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
    }

    // MARK: - Sections

    private var basicSection: some View {
        Section("General") {
            TextField("Name", text: $name)
                .accessibilityIdentifier("restForm.nameField")

            TextField("Endpoint URL", text: $endpoint)
                .textContentType(.URL)
                .autocorrectionDisabled()
                #if os(iOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                #endif
                .accessibilityIdentifier("restForm.endpointField")

            Toggle("Send only new data", isOn: $incrementalOnly)
                .accessibilityLabel("Send only new data since last export")
                .accessibilityIdentifier("restForm.incrementalToggle")
        }
    }

    private var headersSection: some View {
        Section {
            ForEach($headers) { $entry in
                HStack(spacing: 8) {
                    TextField("Header", text: $entry.key)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

                    TextField("Value", text: $entry.value)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
            }
            .onDelete { indices in
                headers.remove(atOffsets: indices)
                if headers.isEmpty { headers.append(HeaderEntry()) }
            }

            Button {
                headers.append(HeaderEntry())
            } label: {
                Label("Add Header", systemImage: "plus")
            }
            .accessibilityIdentifier("restForm.addHeaderButton")
        } header: {
            Text("HTTP Headers")
        } footer: {
            Text("e.g. Authorization: Bearer token123")
        }
    }

    private var payloadSection: some View {
        Section("Payload Format") {
            Picker("Format", selection: $exportFormat) {
                Text("JSON v2 (grouped)").tag("json_v2")
                Text("JSON v1 (flat)").tag("json_v1")
                Text("CSV").tag("csv")
            }
            .accessibilityLabel("Payload format")
            .accessibilityIdentifier("restForm.formatPicker")
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
            .accessibilityLabel("Select health data types, \(enabledTypes.count) selected")
            .accessibilityIdentifier("restForm.typePickerButton")
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
                                            .foregroundStyle(AppColors.primary)
                                    }
                                }
                            }
                            .accessibilityLabel("\(type.displayName), \(enabledTypes.contains(type.rawValue) ? "selected" : "not selected")")
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
            && !endpoint.trimmingCharacters(in: .whitespaces).isEmpty
            && URL(string: endpoint) != nil
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
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespaces)

        // Build headers dict, filtering empty entries
        let headerDict = headers.reduce(into: [String: String]()) { result, entry in
            let key = entry.key.trimmingCharacters(in: .whitespaces)
            let value = entry.value.trimmingCharacters(in: .whitespaces)
            if !key.isEmpty && !value.isEmpty {
                result[key] = value
            }
        }

        if let config = existing {
            config.name = trimmedName
            config.endpoint = trimmedEndpoint
            config.exportFormat = exportFormat
            config.incrementalOnly = incrementalOnly
            config.enabledTypeRawValues = Array(enabledTypes)
            config.httpHeaders = headerDict
            config.updatedAt = Date()
        } else {
            let config = AutomationConfiguration(
                name: trimmedName,
                automationType: "rest_api",
                endpoint: trimmedEndpoint,
                exportFormat: exportFormat
            )
            config.incrementalOnly = incrementalOnly
            config.enabledTypeRawValues = Array(enabledTypes)
            config.httpHeaders = headerDict
            modelContext.insert(config)
        }

        try? modelContext.save()
        NotificationCenter.default.post(name: .automationsDidChange, object: nil)
        dismiss()
    }
}

// MARK: - Header Entry

/// Editable key-value pair for HTTP headers.
private struct HeaderEntry: Identifiable {
    let id = UUID()
    var key: String = ""
    var value: String = ""
}
