import Foundation
import Network
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Network Server

/// Actor that runs a TLS-secured HTTP server for health data transfer.
/// Serves /api/v1/pair, /status, /health/types, /health/data endpoints.
actor NetworkServer {

    // MARK: - State

    enum ServerState: Sendable {
        case stopped
        case starting
        case running(port: UInt16)
        case failed(Error)
    }

    private(set) var state: ServerState = .stopped
    private var listener: NWListener?
    private var activeConnections: [NWConnection] = []

    private let healthKitService: HealthKitService
    private let pairingService: PairingService
    private let auditService: AuditService
    private let certificateService: CertificateService

    private let port: UInt16

    init(
        port: UInt16 = 0, // 0 = auto-assign
        healthKitService: HealthKitService,
        pairingService: PairingService,
        auditService: AuditService,
        certificateService: CertificateService
    ) {
        self.port = port
        self.healthKitService = healthKitService
        self.pairingService = pairingService
        self.auditService = auditService
        self.certificateService = certificateService
    }

    // MARK: - Server Lifecycle

    /// Start the TLS server.
    func start() async throws {
        guard case .stopped = state else {
            Loggers.network.warning("Server already running or starting")
            return
        }

        state = .starting

        // Create TLS parameters
        let tlsOptions = NWProtocolTLS.Options()

        // Try to set up TLS with certificate
        do {
            let identity = try await certificateService.getOrCreateIdentity()
            let secIdentity = sec_identity_create(identity)
            sec_protocol_options_set_local_identity(
                tlsOptions.securityProtocolOptions,
                secIdentity!
            )
            sec_protocol_options_set_min_tls_protocol_version(
                tlsOptions.securityProtocolOptions,
                .TLSv12
            )
        } catch {
            Loggers.network.error("TLS setup failed, starting without TLS: \(error.localizedDescription)")
        }

        let tcpOptions = NWProtocolTCP.Options()
        let params = NWParameters(tls: tlsOptions, tcp: tcpOptions)

        let nwPort: NWEndpoint.Port = port == 0 ? .any : NWEndpoint.Port(rawValue: port)!
        let newListener = try NWListener(using: params, on: nwPort)

        newListener.stateUpdateHandler = { [weak self] newState in
            Task { [weak self] in
                await self?.handleListenerStateChange(newState)
            }
        }

        newListener.newConnectionHandler = { [weak self] connection in
            Task { [weak self] in
                await self?.handleNewConnection(connection)
            }
        }

        listener = newListener
        newListener.start(queue: .global(qos: .userInitiated))

        Loggers.network.info("Network server starting on port \(self.port)")
    }

    /// Stop the server and close all connections.
    func stop() {
        listener?.cancel()
        listener = nil

        for connection in activeConnections {
            connection.cancel()
        }
        activeConnections.removeAll()

        state = .stopped
        Loggers.network.info("Network server stopped")
    }

    /// The port the server is actually listening on (after auto-assign).
    var actualPort: UInt16? {
        if case .running(let port) = state {
            return port
        }
        return listener?.port?.rawValue
    }

    // MARK: - Listener State

    private func handleListenerStateChange(_ newState: NWListener.State) {
        switch newState {
        case .ready:
            let actualPort = listener?.port?.rawValue ?? port
            state = .running(port: actualPort)
            Loggers.network.info("Server listening on port \(actualPort)")

        case .failed(let error):
            state = .failed(error)
            Loggers.network.error("Server failed: \(error.localizedDescription)")

        case .cancelled:
            state = .stopped

        default:
            break
        }
    }

    // MARK: - Connection Handling

    private func handleNewConnection(_ connection: NWConnection) {
        activeConnections.append(connection)

        connection.stateUpdateHandler = { [weak self] state in
            if case .cancelled = state {
                Task { [weak self] in
                    await self?.removeConnection(connection)
                }
            }
        }

        connection.start(queue: .global(qos: .userInitiated))
        receiveRequest(on: connection)
    }

    private func removeConnection(_ connection: NWConnection) {
        activeConnections.removeAll { $0 === connection }
    }

    private nonisolated func receiveRequest(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            Task {
                if let data, let request = HTTPRequest.parse(data) {
                    let response = await self.handleRequest(request)
                    await self.sendResponse(response, on: connection)
                } else if let error {
                    Loggers.network.error("Receive error: \(error.localizedDescription)")
                    connection.cancel()
                } else if isComplete {
                    connection.cancel()
                }
            }
        }
    }

    private nonisolated func sendResponse(_ response: HTTPResponse, on connection: NWConnection) async {
        let data = response.serialize()

        connection.send(content: data, completion: .contentProcessed { error in
            if let error {
                Loggers.network.error("Send error: \(error.localizedDescription)")
            }
            connection.cancel()
        })
    }

    // MARK: - Request Routing

    private func handleRequest(_ request: HTTPRequest) async -> HTTPResponse {
        await auditService.log(event: .requestReceived(
            method: request.method.rawValue,
            path: request.path
        ))

        switch (request.method, request.path) {
        case (.GET, "/status"):
            return await handleStatus()

        case (.POST, "/api/v1/pair"):
            return await handlePair(request)

        case (.GET, "/health/types"):
            return await handleHealthTypes(request)

        case (.GET, "/health/data"):
            return await handleHealthData(request)

        default:
            return .error(statusCode: 404, message: "Not Found")
        }
    }

    // MARK: - Route Handlers

    private func handleStatus() async -> HTTPResponse {
        let availableTypes = await healthKitService.availableTypes()
        let status = ServerStatus(
            status: "running",
            version: "1.0",
            deviceName: await deviceName(),
            availableTypes: availableTypes.count
        )
        return .json(APIResponse(success: true, data: status, error: nil))
    }

    private func handlePair(_ request: HTTPRequest) async -> HTTPResponse {
        guard let body = request.body,
              let pairRequest = try? JSONDecoder().decode(PairRequest.self, from: body) else {
            return .error(statusCode: 400, message: "Missing or invalid pairing code in request body")
        }

        guard let token = await pairingService.validateCode(pairRequest.code) else {
            await auditService.log(event: .pairingFailed(reason: "Invalid code"))
            return .error(statusCode: 401, message: "Invalid or expired pairing code")
        }

        // Register the device token mapping (device name included in response for caller to store)
        let deviceID = UUID().uuidString
        await pairingService.registerDevice(deviceID: deviceID, token: token)

        await auditService.log(event: .pairingSucceeded)

        let pairResponse = PairResponse(token: token, deviceID: deviceID, expiresIn: nil)
        return .json(APIResponse(success: true, data: pairResponse, error: nil))
    }

    private func handleHealthTypes(_ request: HTTPRequest) async -> HTTPResponse {
        guard let token = request.bearerToken,
              await pairingService.validateToken(token) else {
            return .error(statusCode: 401, message: "Unauthorized")
        }

        let availableTypes = await healthKitService.availableTypes()
        let typeInfos = availableTypes.map { item in
            HealthTypeInfo(
                identifier: item.type.rawValue,
                displayName: item.type.displayName,
                sampleCount: item.count
            )
        }

        let response = HealthTypesResponse(types: typeInfos)
        return .json(APIResponse(success: true, data: response, error: nil))
    }

    private func handleHealthData(_ request: HTTPRequest) async -> HTTPResponse {
        guard let token = request.bearerToken,
              await pairingService.validateToken(token) else {
            return .error(statusCode: 401, message: "Unauthorized")
        }

        guard let typeString = request.queryParameters["type"],
              let dataType = HealthDataType(rawValue: typeString) else {
            return .error(statusCode: 400, message: "Missing or invalid 'type' query parameter")
        }

        let offset = Int(request.queryParameters["offset"] ?? "0") ?? 0
        let limit = min(Int(request.queryParameters["limit"] ?? "500") ?? 500, 1000)

        do {
            let batch = try await healthKitService.fetchBatch(
                for: dataType,
                offset: offset,
                limit: limit
            )

            await auditService.log(event: .dataAccessed(
                type: dataType.rawValue,
                count: batch.samples.count
            ))

            return .json(APIResponse(success: true, data: batch, error: nil))
        } catch {
            Loggers.network.error("Failed to fetch health data: \(error.localizedDescription)")
            return .error(statusCode: 500, message: "Failed to fetch health data")
        }
    }

    // MARK: - Helpers

    private nonisolated func deviceName() async -> String {
        #if os(iOS)
        await MainActor.run { UIDevice.current.name }
        #elseif os(macOS)
        Host.current().localizedName ?? "Mac"
        #else
        "Unknown"
        #endif
    }
}
