import Foundation
import CocoaMQTT

// MARK: - MQTT Push Parameters

/// Sendable snapshot of AutomationConfiguration fields needed for an MQTT push.
/// Extract this on the main actor before crossing into the MQTTAutomation actor.
struct MQTTPushParameters: Sendable {
    let name: String
    let brokerHost: String
    let brokerPort: UInt16
    let topic: String
    let qos: CocoaMQTTQoS
    let useTLS: Bool
    let username: String?
    let password: String?
    let homeAssistantDiscovery: Bool
    let exportFormat: String
    let incrementalOnly: Bool
    let lastTriggeredAt: Date?
    let enabledTypeRawValues: [String]

    init(configuration: AutomationConfiguration) {
        self.name = configuration.name
        self.brokerHost = configuration.endpoint ?? "localhost"
        self.brokerPort = UInt16(configuration.port ?? 1883)
        self.topic = configuration.topic ?? "healthkit/data"
        self.useTLS = configuration.mqttUseTLS
        self.username = configuration.mqttUsername
        self.password = configuration.mqttPassword
        self.homeAssistantDiscovery = configuration.mqttHomeAssistantDiscovery
        self.exportFormat = configuration.exportFormat
        self.incrementalOnly = configuration.incrementalOnly
        self.lastTriggeredAt = configuration.lastTriggeredAt
        self.enabledTypeRawValues = configuration.enabledTypeRawValues

        switch configuration.mqttQoS {
        case 1: self.qos = .qos1
        case 2: self.qos = .qos2
        default: self.qos = .qos0
        }
    }
}

// MARK: - MQTT Connection State

/// Observable connection state for the MQTT broker, shown in the UI.
@MainActor
class MQTTConnectionState: ObservableObject {
    @Published var state: ConnectionStatus = .disconnected
    @Published var lastError: String?

    enum ConnectionStatus: String {
        case disconnected = "Disconnected"
        case connecting = "Connecting"
        case connected = "Connected"
    }
}

// MARK: - MQTT Automation

/// Publishes health data to a user-configured MQTT broker.
/// Supports optional TLS, credentials, configurable QoS, and Home Assistant MQTT discovery.
class MQTTAutomation: NSObject {

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    // MARK: - MQTT Client

    private var mqtt: CocoaMQTT?
    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var publishContinuation: CheckedContinuation<Void, Error>?

    /// Shared connection state for UI observation.
    let connectionState = MQTTConnectionState()

    // MARK: - Constants

    private static let connectTimeout: TimeInterval = 10

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
        super.init()
    }

    // MARK: - Execute

    /// Execute an MQTT push with the given parameters.
    func execute(params: MQTTPushParameters) async throws {
        // Connect to broker
        try await connect(params: params)

        defer { disconnect() }

        // Fetch health data
        let samples = try await fetchSamples(params: params)

        guard !samples.isEmpty else {
            Loggers.automation.info("MQTT automation '\(params.name)': no samples to send")
            return
        }

        // Publish Home Assistant discovery if enabled
        if params.homeAssistantDiscovery {
            try await publishHomeAssistantDiscovery(params: params, samples: samples)
        }

        // Format and publish data
        let payload = try formatPayload(samples: samples, format: params.exportFormat)
        try await publish(topic: params.topic, payload: payload, qos: params.qos)

        Loggers.automation.info("MQTT automation '\(params.name)': published \(samples.count) samples to \(params.topic)")
    }

    // MARK: - Connect

    private func connect(params: MQTTPushParameters) async throws {
        let clientID = "HealthAppTransfer-\(UUID().uuidString.prefix(8))"
        let client = CocoaMQTT(clientID: clientID, host: params.brokerHost, port: params.brokerPort)

        client.username = params.username
        client.password = params.password
        client.enableSSL = params.useTLS
        client.keepAlive = 60
        client.autoReconnect = true
        client.maxAutoReconnectTimeInterval = 30
        client.delegate = self

        self.mqtt = client

        await MainActor.run {
            connectionState.state = .connecting
            connectionState.lastError = nil
        }

        // Connect with async/await bridge
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.connectContinuation = continuation

            let connected = client.connect(timeout: Self.connectTimeout)
            if !connected {
                self.connectContinuation = nil
                continuation.resume(throwing: MQTTAutomationError.connectionFailed)
            }
        }
    }

    // MARK: - Disconnect

    private func disconnect() {
        mqtt?.disconnect()
        mqtt = nil
        Task { @MainActor in
            connectionState.state = .disconnected
        }
    }

    // MARK: - Publish

    private func publish(topic: String, payload: Data, qos: CocoaMQTTQoS) async throws {
        guard let client = mqtt else {
            throw MQTTAutomationError.notConnected
        }

        let message = CocoaMQTTMessage(topic: topic, payload: [UInt8](payload), qos: qos, retained: false)

        // For QoS 0, publish is fire-and-forget
        if qos == .qos0 {
            client.publish(message)
            return
        }

        // For QoS 1/2, wait for ack
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.publishContinuation = continuation
            client.publish(message)
        }
    }

    private func publishString(topic: String, payload: String, qos: CocoaMQTTQoS) async throws {
        guard let data = payload.data(using: .utf8) else {
            throw MQTTAutomationError.encodingFailed
        }
        try await publish(topic: topic, payload: data, qos: qos)
    }

    // MARK: - Fetch Samples

    private func fetchSamples(params: MQTTPushParameters) async throws -> [HealthSampleDTO] {
        let types = params.enabledTypeRawValues.compactMap { HealthDataType(rawValue: $0) }

        guard !types.isEmpty else {
            throw MQTTAutomationError.noTypesConfigured
        }

        let startDate: Date? = params.incrementalOnly ? params.lastTriggeredAt : nil

        var allSamples: [HealthSampleDTO] = []
        for type in types {
            guard type.isSampleBased else { continue }
            let samples = try await healthKitService.fetchSampleDTOs(
                for: type,
                from: startDate
            )
            allSamples.append(contentsOf: samples)
        }

        return allSamples
    }

    // MARK: - Format Payload

    private func formatPayload(samples: [HealthSampleDTO], format: String) throws -> Data {
        let formatter: any ExportFormatter

        switch format {
        case "json_v1":
            formatter = JSONv1Formatter()
        case "csv":
            formatter = CSVFormatter()
        default:
            formatter = JSONv2Formatter()
        }

        let options = ExportOptions()
        return try formatter.format(samples: samples, options: options)
    }

    // MARK: - Home Assistant MQTT Discovery

    /// Publishes Home Assistant MQTT discovery config messages so entities auto-appear.
    /// See: https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery
    private func publishHomeAssistantDiscovery(params: MQTTPushParameters, samples: [HealthSampleDTO]) async throws {
        // Collect unique types from the samples
        let uniqueTypes = Set(samples.map { $0.type })

        for type in uniqueTypes {
            let objectId = "healthkit_\(type.rawValue.replacingOccurrences(of: ".", with: "_"))"
            let discoveryTopic = "homeassistant/sensor/\(objectId)/config"

            let config: [String: Any] = [
                "name": type.displayName,
                "state_topic": params.topic,
                "unique_id": objectId,
                "value_template": "{{ value_json['\(type.rawValue)'] | default('unknown') }}",
                "device": [
                    "identifiers": ["healthkit_transfer"],
                    "name": "HealthKit Transfer",
                    "manufacturer": "Apple Health",
                    "model": "iOS"
                ],
                "unit_of_measurement": type.defaultUnit ?? ""
            ]

            let data = try JSONSerialization.data(withJSONObject: config, options: [.sortedKeys])
            try await publish(topic: discoveryTopic, payload: data, qos: .qos1)
        }

        Loggers.automation.info("MQTT: published HA discovery for \(uniqueTypes.count) sensor types")
    }
}

// MARK: - CocoaMQTTDelegate

extension MQTTAutomation: CocoaMQTTDelegate {

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            Task { @MainActor in
                connectionState.state = .connected
            }
            connectContinuation?.resume()
            connectContinuation = nil
        } else {
            let error = MQTTAutomationError.connectionRejected(ack.description)
            Task { @MainActor in
                connectionState.state = .disconnected
                connectionState.lastError = ack.description
            }
            connectContinuation?.resume(throwing: error)
            connectContinuation = nil
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        // Called when message is sent (QoS 0) or fully acked (QoS 1/2)
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        // QoS 1 ack received
        publishContinuation?.resume()
        publishContinuation = nil
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishComplete id: UInt16) {
        // QoS 2 complete
        publishContinuation?.resume()
        publishContinuation = nil
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        // Not subscribing to anything — no-op
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        // Not subscribing — no-op
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        // Not subscribing — no-op
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {}

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        Task { @MainActor in
            connectionState.state = .disconnected
            if let err {
                connectionState.lastError = err.localizedDescription
            }
        }

        // If we're still waiting on a connect, fail it
        if let continuation = connectContinuation {
            connectContinuation = nil
            continuation.resume(throwing: err ?? MQTTAutomationError.connectionFailed)
        }

        // If we're waiting on a publish, fail it
        if let continuation = publishContinuation {
            publishContinuation = nil
            continuation.resume(throwing: err ?? MQTTAutomationError.publishFailed)
        }
    }
}

// MARK: - Errors

enum MQTTAutomationError: LocalizedError {
    case connectionFailed
    case connectionRejected(String)
    case notConnected
    case noTypesConfigured
    case publishFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to MQTT broker."
        case .connectionRejected(let reason):
            return "MQTT broker rejected connection: \(reason)."
        case .notConnected:
            return "Not connected to MQTT broker."
        case .noTypesConfigured:
            return "No health data types configured."
        case .publishFailed:
            return "Failed to publish MQTT message."
        case .encodingFailed:
            return "Failed to encode MQTT payload."
        }
    }
}
