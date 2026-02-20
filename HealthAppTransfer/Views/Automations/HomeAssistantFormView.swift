import SwiftData
import SwiftUI

// MARK: - Home Assistant Form View

/// Form for creating or editing a Home Assistant automation configuration.
/// Stores the long-lived access token in Keychain (not SwiftData).
struct HomeAssistantFormView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var name: String
    @State private var baseURL: String
    @State private var accessToken: String
    @State private var incrementalOnly: Bool
    @State private var enabledTypes: Set<String>
    @State private var showingTypePicker = false
    @State private var isTesting = false
    @State private var testResult: TestResult?

    /// Existing configuration to edit, or nil when creating new.
    private let existing: AutomationConfiguration?
    private let keychain = KeychainStore()

    // MARK: - Init

    init(configuration: AutomationConfiguration? = nil) {
        self.existing = configuration
        _name = State(initialValue: configuration?.name ?? "")
        _baseURL = State(initialValue: configuration?.endpoint ?? "")
        _accessToken = State(initialValue: "")
        _incrementalOnly = State(initialValue: configuration?.incrementalOnly ?? true)
        _enabledTypes = State(initialValue: Set(configuration?.enabledTypeRawValues ?? []))
    }

    // MARK: - Body

    var body: some View {
        Form {
            connectionSection
            optionsSection
            dataTypesSection
            connectionTestSection
        }
        .navigationTitle(existing == nil ? "New Home Assistant" : "Edit Automation")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
                    .accessibilityIdentifier("haForm.saveButton")
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
        .task {
            await loadToken()
        }
    }

    // MARK: - Sections

    private var connectionSection: some View {
        Section {
            TextField("Name", text: $name)
                .accessibilityIdentifier("haForm.nameField")

            TextField("Home Assistant URL", text: $baseURL, prompt: Text("http://homeassistant.local:8123"))
                .textContentType(.URL)
                .autocorrectionDisabled()
                #if os(iOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                #endif
                .accessibilityIdentifier("haForm.urlField")

            SecureField("Long-Lived Access Token", text: $accessToken)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .accessibilityIdentifier("haForm.tokenField")
        } header: {
            Text("Connection")
        } footer: {
            Text("Create a long-lived access token in Home Assistant under Profile \u{2192} Security.")
        }
    }

    private var optionsSection: some View {
        Section("Options") {
            Toggle("Send only new data", isOn: $incrementalOnly)
                .accessibilityLabel("Send only new data since last export")
                .accessibilityIdentifier("haForm.incrementalToggle")
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
            .accessibilityIdentifier("haForm.typePickerButton")
        }
    }

    private var connectionTestSection: some View {
        Section {
            Button {
                Task { await testConnection() }
            } label: {
                HStack {
                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                        Text("Testing...")
                    } else {
                        Label("Test Connection", systemImage: "network")
                    }
                }
            }
            .disabled(baseURL.trimmingCharacters(in: .whitespaces).isEmpty
                      || accessToken.trimmingCharacters(in: .whitespaces).isEmpty
                      || isTesting)
            .accessibilityIdentifier("haForm.testButton")

            if let result = testResult {
                HStack(spacing: 8) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.success ? .green : .red)
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(result.success ? Color.primary : Color.red)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Connection test: \(result.message)")
            }
        } header: {
            Text("Validation")
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
            && !baseURL.trimmingCharacters(in: .whitespaces).isEmpty
            && !accessToken.trimmingCharacters(in: .whitespaces).isEmpty
            && URL(string: baseURL) != nil
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

    private func testConnection() async {
        isTesting = true
        testResult = nil

        let automation = HomeAssistantAutomation(healthKitService: HealthKitService())

        do {
            try await automation.testConnection(
                baseURL: baseURL.trimmingCharacters(in: .whitespaces),
                accessToken: accessToken.trimmingCharacters(in: .whitespaces)
            )
            testResult = TestResult(success: true, message: "Connected successfully")
        } catch {
            testResult = TestResult(success: false, message: error.localizedDescription)
        }

        isTesting = false
    }

    private func loadToken() async {
        guard let config = existing else { return }
        let keychainKey = HomeAssistantAutomation.keychainKeyPrefix + config.persistentModelID.hashValue.description
        if let tokenData = try? await keychain.load(key: keychainKey),
           let token = String(data: tokenData, encoding: .utf8) {
            accessToken = token
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespaces)
        let trimmedToken = accessToken.trimmingCharacters(in: .whitespaces)

        if let config = existing {
            config.name = trimmedName
            config.endpoint = trimmedURL
            config.incrementalOnly = incrementalOnly
            config.enabledTypeRawValues = Array(enabledTypes)
            config.updatedAt = Date()

            // Save token to Keychain
            let keychainKey = HomeAssistantAutomation.keychainKeyPrefix + config.persistentModelID.hashValue.description
            if let tokenData = trimmedToken.data(using: .utf8) {
                Task { try? await keychain.save(key: keychainKey, data: tokenData) }
            }
        } else {
            let config = AutomationConfiguration(
                name: trimmedName,
                automationType: "home_assistant",
                endpoint: trimmedURL
            )
            config.incrementalOnly = incrementalOnly
            config.enabledTypeRawValues = Array(enabledTypes)
            modelContext.insert(config)

            // Save after insert so persistentModelID is assigned
            try? modelContext.save()

            let keychainKey = HomeAssistantAutomation.keychainKeyPrefix + config.persistentModelID.hashValue.description
            if let tokenData = trimmedToken.data(using: .utf8) {
                Task { try? await keychain.save(key: keychainKey, data: tokenData) }
            }
        }

        try? modelContext.save()
        NotificationCenter.default.post(name: .automationsDidChange, object: nil)
        dismiss()
    }
}

// MARK: - Test Result

private struct TestResult {
    let success: Bool
    let message: String
}
