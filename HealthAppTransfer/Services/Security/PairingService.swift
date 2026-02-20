import CryptoKit
import Foundation

// MARK: - Pairing Service

/// Manages time-limited pairing codes, bearer token validation, and token-to-device mapping.
/// Device metadata is stored in SwiftData (PairedDevice model); this actor handles the token side.
actor PairingService {

    // MARK: - Types

    struct PairingCode: Sendable {
        let code: String
        let expiresAt: Date
        let token: String

        var isExpired: Bool { Date() > expiresAt }
    }

    // MARK: - State

    private var activeCodes: [String: PairingCode] = [:]
    private var validTokens: Set<String> = []
    /// Maps PairedDevice.deviceID → bearer token for revocation lookup.
    private var deviceTokenMap: [String: String] = [:]
    private let codeLength: Int = 6
    private let codeLifetime: TimeInterval = 300 // 5 minutes

    private let keychain: KeychainStore
    private static let tokensKey = "pairingValidTokens"
    private static let deviceMapKey = "pairingDeviceTokenMap"

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    // MARK: - Initialization

    /// Load persisted tokens and device mappings from Keychain.
    /// Call this once at app launch.
    func loadPersistedTokens() async {
        do {
            if let tokens: [String] = try await keychain.load(key: Self.tokensKey, as: [String].self) {
                validTokens = Set(tokens)
                Loggers.pairing.info("Loaded \(tokens.count) persisted token(s)")
            }
            if let map: [String: String] = try await keychain.load(key: Self.deviceMapKey, as: [String: String].self) {
                deviceTokenMap = map
            }
        } catch {
            Loggers.pairing.error("Failed to load persisted tokens: \(error.localizedDescription)")
        }
    }

    // MARK: - Code Generation

    /// Generate a new time-limited pairing code.
    /// Returns the code (for display/QR) and the associated bearer token.
    func generatePairingCode() -> PairingCode {
        let code = generateNumericCode(length: codeLength)
        let token = generateBearerToken()
        let expiresAt = Date().addingTimeInterval(codeLifetime)

        let pairingCode = PairingCode(code: code, expiresAt: expiresAt, token: token)
        activeCodes[code] = pairingCode

        // Clean expired codes
        cleanExpiredCodes()

        Loggers.pairing.info("Generated pairing code (expires in \(Int(self.codeLifetime))s)")
        return pairingCode
    }

    // MARK: - Code Validation

    /// Validate a pairing code and return the bearer token if valid.
    /// Consumes the code (single-use).
    func validateCode(_ code: String) -> String? {
        cleanExpiredCodes()

        guard let pairingCode = activeCodes[code], !pairingCode.isExpired else {
            Loggers.pairing.warning("Invalid or expired pairing code attempted")
            return nil
        }

        // Consume the code
        activeCodes.removeValue(forKey: code)

        // Register the token
        validTokens.insert(pairingCode.token)

        Loggers.pairing.info("Pairing code validated, token registered")
        return pairingCode.token
    }

    // MARK: - Token Validation

    /// Check if a bearer token is valid.
    func validateToken(_ token: String) -> Bool {
        validTokens.contains(token)
    }

    // MARK: - Device Registration

    /// Associate a bearer token with a SwiftData PairedDevice deviceID.
    /// Call after creating the PairedDevice in SwiftData.
    func registerDevice(deviceID: String, token: String) {
        deviceTokenMap[deviceID] = token
        persistState()
        Loggers.pairing.info("Registered device \(deviceID) with bearer token")
    }

    /// Revoke the token for a specific device.
    func revokeDeviceToken(deviceID: String) {
        if let token = deviceTokenMap.removeValue(forKey: deviceID) {
            validTokens.remove(token)
        }
        persistState()
        Loggers.pairing.info("Revoked token for device \(deviceID)")
    }

    /// Revoke a specific bearer token directly.
    func revokeToken(_ token: String) {
        validTokens.remove(token)
        deviceTokenMap = deviceTokenMap.filter { $0.value != token }
        persistState()
        Loggers.pairing.info("Bearer token revoked")
    }

    /// Revoke all active tokens and codes.
    func revokeAll() {
        activeCodes.removeAll()
        validTokens.removeAll()
        deviceTokenMap.removeAll()
        persistState()
        Loggers.pairing.info("All pairing codes and tokens revoked")
    }

    /// Returns the number of active (non-expired) codes.
    var activeCodeCount: Int {
        cleanExpiredCodes()
        return activeCodes.count
    }

    /// Returns the number of valid tokens.
    var validTokenCount: Int {
        validTokens.count
    }

    // MARK: - Private Helpers

    private func generateNumericCode(length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            code += String(Int.random(in: 0...9))
        }
        return code
    }

    private func generateBearerToken() -> String {
        // Generate a 32-byte random token, base64url-encoded
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    @discardableResult
    private func cleanExpiredCodes() -> Int {
        let now = Date()
        let before = activeCodes.count
        activeCodes = activeCodes.filter { !$0.value.isExpired || $0.value.expiresAt > now }
        return before - activeCodes.count
    }

    private func persistState() {
        Task { [weak self] in
            guard let self else { return }
            let tokens = await Array(self.validTokens)
            let map = await self.deviceTokenMap
            do {
                try await self.keychain.save(key: Self.tokensKey, value: tokens)
                try await self.keychain.save(key: Self.deviceMapKey, value: map)
            } catch {
                Loggers.pairing.error("Failed to persist pairing state: \(error.localizedDescription)")
            }
        }
    }
}
