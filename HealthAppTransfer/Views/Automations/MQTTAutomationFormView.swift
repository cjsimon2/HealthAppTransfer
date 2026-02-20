import SwiftData
import SwiftUI

// MARK: - MQTT Automation Form View

/// Form for creating or editing an MQTT automation configuration.
struct MQTTAutomationFormView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var name: String
    @State private var brokerHost: String
    @State private var brokerPort: String
    @State private var topic: String
    @State private var qosLevel: Int
    @State private var useTLS: Bool
    @State private var username: String
    @State private var password: String
    @State private var homeAssistantDiscovery: Bool
    @State private var enabledTypes: Set<String>
    @State private var showingTypePicker = false
    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    @State private var isTesting = false

    /// Existing configuration to edit, or nil when creating new.
    private let existing: AutomationConfiguration?

    // MARK: - Init

    init(configuration: AutomationConfiguration? = nil) {
        self.existing = configuration
        _name = State(initialValue: configuration?.name ?? "")
        _brokerHost = State(initialValue: configuration?.endpoint ?? "")
        _brokerPort = State(initialValue: String(configuration?.port ?? 1883))
        _topic = State(initialValue: configuration?.topic ?? "healthkit/data")
        _qosLevel = State(initialValue: configuration?.mqttQoS ?? 0)
        _useTLS = State(initialValue: configuration?.mqttUseTLS ?? false)
        _username = State(initialValue: configuration?.mqttUsername ?? "")
        _password = State(initialValue: configuration?.mqttPassword ?? "")
        _homeAssistantDiscovery = State(initialValue: configuration?.mqttHomeAssistantDiscovery ?? false)
        _enabledTypes = State(initialValue: Set(configuration?.enabledTypeRawValues ?? []))
    }

    // MARK: - Body

    var body: some View {
        Form {
            brokerSection
            authenticationSection
            topicSection
            homeAssistantSection
            dataTypesSection
            testSection
        }
        .navigationTitle(existing == nil ? "New MQTT Automation" : "Edit MQTT Automation")
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
        .alert("Connection Test", isPresented: $showingTestResult) {
            Button("OK") {}
        } message: {
            Text(testResultMessage)
        }
    }

    // MARK: - Sections

    private var brokerSection: some View {
        Section {
            TextField("Name", text: $name)

            TextField("Broker Host", text: $brokerHost)
                .autocorrectionDisabled()
                #if os(iOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                #endif

            TextField("Port", text: $brokerPort)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif

            Toggle("Use TLS", isOn: $useTLS)
        } header: {
            Text("Broker")
        } footer: {
            Text("e.g. mqtt.example.com, port 1883 (or 8883 for TLS)")
        }
    }

    private var authenticationSection: some View {
        Section {
            TextField("Username", text: $username)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

            SecureField("Password", text: $password)
        } header: {
            Text("Authentication")
        } footer: {
            Text("Leave blank if the broker doesn't require authentication.")
        }
    }

    private var topicSection: some View {
        Section {
            TextField("Topic", text: $topic)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

            Picker("QoS Level", selection: $qosLevel) {
                Text("0 — At most once").tag(0)
                Text("1 — At least once").tag(1)
                Text("2 — Exactly once").tag(2)
            }
        } header: {
            Text("Publishing")
        } footer: {
            Text("Topic where health data JSON will be published.")
        }
    }

    private var homeAssistantSection: some View {
        Section {
            Toggle("Auto-Discovery", isOn: $homeAssistantDiscovery)
        } header: {
            Text("Home Assistant")
        } footer: {
            Text("Publishes MQTT discovery messages so Home Assistant automatically creates sensor entities for each health data type.")
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

    private var testSection: some View {
        Section {
            Button {
                testConnection()
            } label: {
                HStack {
                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                        Text("Testing...")
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Test Connection")
                    }
                }
            }
            .disabled(brokerHost.trimmingCharacters(in: .whitespaces).isEmpty || isTesting)
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
            && !brokerHost.trimmingCharacters(in: .whitespaces).isEmpty
            && !topic.trimmingCharacters(in: .whitespaces).isEmpty
            && !enabledTypes.isEmpty
            && (UInt16(brokerPort) != nil)
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
        let trimmedHost = brokerHost.trimmingCharacters(in: .whitespaces)
        let trimmedTopic = topic.trimmingCharacters(in: .whitespaces)
        let parsedPort = Int(brokerPort) ?? 1883

        if let config = existing {
            config.name = trimmedName
            config.endpoint = trimmedHost
            config.port = parsedPort
            config.topic = trimmedTopic
            config.mqttQoS = qosLevel
            config.mqttUseTLS = useTLS
            config.mqttUsername = username.isEmpty ? nil : username
            config.mqttPassword = password.isEmpty ? nil : password
            config.mqttHomeAssistantDiscovery = homeAssistantDiscovery
            config.enabledTypeRawValues = Array(enabledTypes)
            config.updatedAt = Date()
        } else {
            let config = AutomationConfiguration(
                name: trimmedName,
                automationType: "mqtt",
                endpoint: trimmedHost,
                exportFormat: "json_v2"
            )
            config.port = parsedPort
            config.topic = trimmedTopic
            config.mqttQoS = qosLevel
            config.mqttUseTLS = useTLS
            config.mqttUsername = username.isEmpty ? nil : username
            config.mqttPassword = password.isEmpty ? nil : password
            config.mqttHomeAssistantDiscovery = homeAssistantDiscovery
            config.enabledTypeRawValues = Array(enabledTypes)
            modelContext.insert(config)
        }

        try? modelContext.save()
        dismiss()
    }

    private func testConnection() {
        isTesting = true
        let host = brokerHost.trimmingCharacters(in: .whitespaces)
        let port = UInt16(brokerPort) ?? 1883

        Task {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let clientID = "HealthAppTransfer-test-\(UUID().uuidString.prefix(8))"
                    let client = CocoaMQTT(clientID: clientID, host: host, port: port)
                    client.enableSSL = useTLS
                    client.username = username.isEmpty ? nil : username
                    client.password = password.isEmpty ? nil : password

                    // Use a simple delegate to capture connection result
                    let testDelegate = MQTTTestDelegate { result in
                        switch result {
                        case .success:
                            client.disconnect()
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    client.delegate = testDelegate

                    let connected = client.connect(timeout: 10)
                    if !connected {
                        continuation.resume(throwing: MQTTAutomationError.connectionFailed)
                    }
                }

                testResultMessage = "Successfully connected to \(host):\(port)"
            } catch {
                testResultMessage = "Connection failed: \(error.localizedDescription)"
            }

            isTesting = false
            showingTestResult = true
        }
    }
}

// MARK: - Test Delegate

import CocoaMQTT

/// Minimal delegate used only for connection testing.
private class MQTTTestDelegate: NSObject, CocoaMQTTDelegate {
    private let completion: (Result<Void, Error>) -> Void
    private var didComplete = false

    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        guard !didComplete else { return }
        didComplete = true
        if ack == .accept {
            completion(.success(()))
        } else {
            completion(.failure(MQTTAutomationError.connectionRejected(ack.description)))
        }
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        guard !didComplete else { return }
        didComplete = true
        completion(.failure(err ?? MQTTAutomationError.connectionFailed))
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {}
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {}
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {}
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {}
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {}
    func mqttDidPing(_ mqtt: CocoaMQTT) {}
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}
}
