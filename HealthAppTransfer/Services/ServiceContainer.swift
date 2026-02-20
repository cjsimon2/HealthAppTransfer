import Foundation

// MARK: - Service Container

/// Centralised dependency container holding all service instances.
/// Created once at app launch and passed into the view hierarchy.
struct ServiceContainer {
    let keychain: KeychainStore
    let certificateService: CertificateService
    let pairingService: PairingService
    let auditService: AuditService
    let healthKitService: HealthKitService
    let biometricService: BiometricService
    let networkServer: NetworkServer
}

// MARK: - Default Init (production wiring)

extension ServiceContainer {

    /// Creates all services with their real dependencies.
    /// The memberwise init remains available for test injection.
    init() {
        let keychain = KeychainStore()
        let certificateService = CertificateService(keychain: keychain)
        let pairingService = PairingService(keychain: keychain)
        let auditService = AuditService()
        let healthKitService = HealthKitService()
        let biometricService = BiometricService()

        self.init(
            keychain: keychain,
            certificateService: certificateService,
            pairingService: pairingService,
            auditService: auditService,
            healthKitService: healthKitService,
            biometricService: biometricService,
            networkServer: NetworkServer(
                healthKitService: healthKitService,
                pairingService: pairingService,
                auditService: auditService,
                certificateService: certificateService,
                biometricService: biometricService
            )
        )
    }
}

// MARK: - ViewModel Factories

extension ServiceContainer {

    @MainActor
    func makePairingViewModel() -> PairingViewModel {
        PairingViewModel(
            pairingService: pairingService,
            certificateService: certificateService,
            networkServer: networkServer
        )
    }

    @MainActor
    func makeLANSyncViewModel() -> LANSyncViewModel {
        LANSyncViewModel(keychain: keychain)
    }

    @MainActor
    func makeSecuritySettingsViewModel() -> SecuritySettingsViewModel {
        SecuritySettingsViewModel(biometricService: biometricService)
    }
}
