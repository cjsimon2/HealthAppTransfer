import CryptoKit
import Foundation

// MARK: - LAN Sync Client

/// Connects to an iPhone's TLS health server over LAN and pulls health data.
/// Uses TLS pinning with the certificate fingerprint from the pairing QR code.
actor LANSyncClient {

    // MARK: - Types

    enum ConnectionState: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)

        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                 (.connecting, .connecting),
                 (.connected, .connected):
                return true
            case (.failed(let a), .failed(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    struct SyncResult: Sendable {
        let typesAvailable: Int
        let samplesFetched: Int
        let duration: TimeInterval
    }

    // MARK: - State

    private(set) var state: ConnectionState = .disconnected
    private var session: URLSession?
    private var baseURL: String?

    private let keychain: KeychainStore

    init(keychain: KeychainStore) {
        self.keychain = keychain
    }

    // MARK: - Connection

    /// Connect to an iPhone server using stored pairing credentials.
    /// - Parameters:
    ///   - host: The server's IP address
    ///   - port: The server's port
    ///   - fingerprint: Expected TLS certificate SHA-256 fingerprint
    ///   - token: Bearer token for API authentication
    func connect(host: String, port: UInt16, fingerprint: String, token: String) async -> Bool {
        state = .connecting
        baseURL = "https://\(host):\(port)"

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 60

        session = URLSession(
            configuration: config,
            delegate: TLSPinningDelegate(expectedFingerprint: fingerprint),
            delegateQueue: nil
        )

        // Verify connection with /status endpoint
        do {
            let status = try await fetchStatus(token: token)
            if status.status == "running" {
                state = .connected
                Loggers.network.info("LANSync: connected to \(host):\(port) — \(status.deviceName)")
                return true
            } else {
                state = .failed("Server not ready")
                return false
            }
        } catch {
            state = .failed(error.localizedDescription)
            Loggers.network.error("LANSync: connection failed — \(error.localizedDescription)")
            return false
        }
    }

    /// Disconnect and clean up the session.
    func disconnect() {
        session?.invalidateAndCancel()
        session = nil
        baseURL = nil
        state = .disconnected
    }

    // MARK: - API Methods

    /// Check server status.
    func fetchStatus(token: String) async throws -> ServerStatus {
        let response: APIResponse<ServerStatus> = try await get("/status", token: token)
        guard let data = response.data else {
            throw LANSyncError.invalidResponse
        }
        return data
    }

    /// Fetch available health data types from the server.
    func fetchHealthTypes(token: String) async throws -> [HealthTypeInfo] {
        let response: APIResponse<HealthTypesResponse> = try await get("/health/types", token: token)
        guard let data = response.data else {
            throw LANSyncError.invalidResponse
        }
        return data.types
    }

    /// Fetch a batch of health data samples.
    func fetchHealthData(type: HealthDataType, offset: Int = 0, limit: Int = 500, token: String) async throws -> HealthDataBatch {
        let path = "/health/data?type=\(type.rawValue)&offset=\(offset)&limit=\(limit)"
        let response: APIResponse<HealthDataBatch> = try await get(path, token: token)
        guard let data = response.data else {
            throw LANSyncError.invalidResponse
        }
        return data
    }

    /// Pull all available health data from the server.
    /// Returns both the sync result summary and the actual samples for persistence.
    func pullAllData(token: String) async throws -> (SyncResult, [HealthSampleDTO]) {
        let start = Date()
        let types = try await fetchHealthTypes(token: token)
        var totalSamples = 0
        var allSamples: [HealthSampleDTO] = []

        for typeInfo in types where typeInfo.sampleCount > 0 {
            guard let dataType = HealthDataType(rawValue: typeInfo.identifier) else { continue }
            var offset = 0
            var hasMore = true

            while hasMore {
                let batch = try await fetchHealthData(type: dataType, offset: offset, token: token)
                totalSamples += batch.samples.count
                allSamples.append(contentsOf: batch.samples)
                hasMore = batch.hasMore
                offset += batch.limit
            }
        }

        let duration = Date().timeIntervalSince(start)
        Loggers.network.info("LANSync: pulled \(totalSamples) samples across \(types.count) types in \(String(format: "%.1f", duration))s")

        let result = SyncResult(
            typesAvailable: types.count,
            samplesFetched: totalSamples,
            duration: duration
        )
        return (result, allSamples)
    }

    // MARK: - Private HTTP

    private func get<T: Codable>(_ path: String, token: String) async throws -> T {
        guard let baseURL, let url = URL(string: baseURL + path) else {
            throw LANSyncError.notConnected
        }
        guard let session else {
            throw LANSyncError.notConnected
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LANSyncError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LANSyncError.serverError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Token Retrieval

    /// Load the bearer token for a paired device from keychain.
    func loadToken(for deviceID: String) async throws -> String {
        guard let data = try await keychain.load(key: "serverToken_\(deviceID)") else {
            throw LANSyncError.noToken
        }
        guard let token = String(data: data, encoding: .utf8) else {
            throw LANSyncError.noToken
        }
        return token
    }
}

// MARK: - Errors

enum LANSyncError: LocalizedError {
    case notConnected
    case invalidResponse
    case serverError(Int)
    case noToken

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to server"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server returned error \(code)"
        case .noToken:
            return "No authentication token found"
        }
    }
}
