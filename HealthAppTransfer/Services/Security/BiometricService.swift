import Foundation
import LocalAuthentication

// MARK: - Biometric Service

/// Provides FaceID/TouchID authentication with passcode fallback.
/// Thread-safe actor wrapping LocalAuthentication framework.
actor BiometricService {

    // MARK: - Types

    enum BiometricType: Sendable {
        case faceID
        case touchID
        case none
    }

    enum BiometricError: LocalizedError, Sendable {
        case notAvailable
        case failed(String)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device."
            case .failed(let reason):
                return reason
            case .cancelled:
                return "Authentication was cancelled."
            }
        }
    }

    // MARK: - State

    /// Whether the app is currently unlocked this session.
    private(set) var isUnlocked = false

    // MARK: - Biometric Availability

    /// The biometric type available on this device.
    nonisolated var availableBiometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }

    /// Whether any biometric (or passcode fallback) is available.
    nonisolated var canAuthenticate: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    // MARK: - Authentication

    /// Authenticate with biometrics, falling back to device passcode.
    /// Returns `true` on success.
    @discardableResult
    func authenticate(reason: String = "Authenticate to access health data") async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if success {
                isUnlocked = true
                Loggers.security.info("Biometric authentication succeeded")
            }
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                Loggers.security.info("Biometric authentication cancelled")
                throw BiometricError.cancelled
            default:
                Loggers.security.error("Biometric authentication failed: \(error.localizedDescription)")
                throw BiometricError.failed(error.localizedDescription)
            }
        }
    }

    /// Re-authenticate for sensitive operations (export, API access).
    /// Always prompts even if already unlocked.
    func reauthenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if success {
                Loggers.security.info("Biometric re-authentication succeeded")
            }
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricError.cancelled
            default:
                throw BiometricError.failed(error.localizedDescription)
            }
        }
    }

    /// Lock the app (require re-authentication).
    func lock() {
        isUnlocked = false
        Loggers.security.info("App locked — biometric auth required")
    }

    /// Unlock without biometrics (used when biometric lock is disabled in settings).
    func unlockWithoutAuth() {
        isUnlocked = true
    }

    // MARK: - Display Name

    /// Human-readable name for the available biometric type.
    nonisolated var biometricName: String {
        switch availableBiometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Passcode"
        }
    }
}
