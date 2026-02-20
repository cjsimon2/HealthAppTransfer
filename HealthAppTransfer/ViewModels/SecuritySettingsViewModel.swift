import SwiftUI
import SwiftData

// MARK: - Security Settings ViewModel

@MainActor
class SecuritySettingsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isBiometricEnabled = false
    @Published var isAuthenticating = false
    @Published var error: String?

    // MARK: - Dependencies

    let biometricService: BiometricService

    // MARK: - Init

    init(biometricService: BiometricService) {
        self.biometricService = biometricService
    }

    // MARK: - Computed

    var biometricName: String {
        biometricService.biometricName
    }

    var canUseBiometrics: Bool {
        biometricService.canAuthenticate
    }

    var biometricIconName: String {
        switch biometricService.availableBiometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.shield"
        }
    }

    // MARK: - Load

    func loadPreference(from context: ModelContext) {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let prefs = try? context.fetch(descriptor).first {
            isBiometricEnabled = prefs.requireBiometricAuth
        }
    }

    // MARK: - Toggle

    func toggleBiometric(enabled: Bool, context: ModelContext) async {
        if enabled {
            // Require authentication before enabling
            isAuthenticating = true
            defer { isAuthenticating = false }

            do {
                try await biometricService.authenticate(
                    reason: "Authenticate to enable biometric lock"
                )
                updatePreference(enabled: true, context: context)
                isBiometricEnabled = true
                error = nil
            } catch BiometricService.BiometricError.cancelled {
                // User cancelled — don't show error, just revert toggle
                isBiometricEnabled = false
            } catch {
                self.error = error.localizedDescription
                isBiometricEnabled = false
            }
        } else {
            // Disabling doesn't require auth
            updatePreference(enabled: false, context: context)
            isBiometricEnabled = false
            error = nil
            await biometricService.unlockWithoutAuth()
        }
    }

    // MARK: - Helpers

    private func updatePreference(enabled: Bool, context: ModelContext) {
        let descriptor = FetchDescriptor<UserPreferences>()
        let prefs: UserPreferences

        if let existing = try? context.fetch(descriptor).first {
            prefs = existing
        } else {
            prefs = UserPreferences()
            context.insert(prefs)
        }

        prefs.requireBiometricAuth = enabled
        prefs.updatedAt = Date()

        try? context.save()
    }
}
