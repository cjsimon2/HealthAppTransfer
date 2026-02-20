import CryptoKit
import Foundation

// MARK: - Pairing Service

/// Manages time-limited pairing codes and bearer token validation for device pairing.
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
    private let codeLength: Int = 6
    private let codeLifetime: TimeInterval = 300 // 5 minutes

    private let keychain: KeychainStore

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
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

    /// Revoke a specific bearer token.
    func revokeToken(_ token: String) {
        validTokens.remove(token)
        Loggers.pairing.info("Bearer token revoked")
    }

    /// Revoke all active tokens and codes.
    func revokeAll() {
        activeCodes.removeAll()
        validTokens.removeAll()
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
}
