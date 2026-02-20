import SwiftUI
import SwiftData

// MARK: - Content View

/// Root view that creates services and delegates to MainTabView.
/// Handles HealthKit authorization on first launch and biometric lock gate.
struct ContentView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State

    @StateObject private var pairingViewModel: PairingViewModel
    @StateObject private var lanSyncViewModel: LANSyncViewModel
    @StateObject private var securitySettingsViewModel: SecuritySettingsViewModel
    @AppStorage("hasRequestedHealthKitAuth") private var hasRequestedHealthKitAuth = false
    @State private var showHealthKitAlert = false
    @State private var showLockedScreen = false

    // MARK: - Services

    private let healthKitService: HealthKitService
    private let biometricService: BiometricService

    // MARK: - Init

    init() {
        let keychain = KeychainStore()
        let certificateService = CertificateService(keychain: keychain)
        let pairingService = PairingService(keychain: keychain)
        let auditService = AuditService()
        let healthKitService = HealthKitService()
        let biometricService = BiometricService()

        let networkServer = NetworkServer(
            healthKitService: healthKitService,
            pairingService: pairingService,
            auditService: auditService,
            certificateService: certificateService,
            biometricService: biometricService
        )

        self.healthKitService = healthKitService
        self.biometricService = biometricService

        _pairingViewModel = StateObject(wrappedValue: PairingViewModel(
            pairingService: pairingService,
            certificateService: certificateService,
            networkServer: networkServer
        ))

        _lanSyncViewModel = StateObject(wrappedValue: LANSyncViewModel(keychain: keychain))

        _securitySettingsViewModel = StateObject(wrappedValue: SecuritySettingsViewModel(
            biometricService: biometricService
        ))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MainTabView(
                pairingViewModel: pairingViewModel,
                lanSyncViewModel: lanSyncViewModel,
                healthKitService: healthKitService,
                securitySettingsViewModel: securitySettingsViewModel
            )

            if showLockedScreen {
                lockedOverlay
            }
        }
        .task {
            await pairingViewModel.pairingService.loadPersistedTokens()
            await requestHealthKitAuthIfNeeded()
            await checkBiometricLockOnLaunch()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                Task { await lockIfEnabled() }
            } else if newPhase == .active, showLockedScreen {
                Task { await authenticateToUnlock() }
            }
        }
        .alert("Health Data Access", isPresented: $showHealthKitAlert) {
            Button("Allow") {
                Task { await authorizeHealthKit() }
            }
            Button("Not Now", role: .cancel) {
                hasRequestedHealthKitAuth = true
            }
        } message: {
            Text("HealthAppTransfer needs access to your health data to display and transfer it between devices.")
        }
    }

    // MARK: - Locked Overlay

    private var lockedOverlay: some View {
        ZStack {
            lockedBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text("HealthAppTransfer is Locked")
                    .font(.title2.weight(.semibold))

                Text("Authenticate to access your health data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await authenticateToUnlock() }
                } label: {
                    Label("Unlock with \(biometricService.biometricName)", systemImage: securitySettingsViewModel.biometricIconName)
                        .font(.headline)
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .transition(.opacity)
    }

    private var lockedBackground: Color {
        #if canImport(UIKit)
        Color(.systemBackground)
        #else
        Color(.windowBackgroundColor)
        #endif
    }

    // MARK: - Biometric Lock

    private func checkBiometricLockOnLaunch() async {
        let isBiometricEnabled = loadBiometricPreference()
        if isBiometricEnabled {
            showLockedScreen = true
            await authenticateToUnlock()
        } else {
            await biometricService.unlockWithoutAuth()
        }
    }

    private func authenticateToUnlock() async {
        do {
            try await biometricService.authenticate(reason: "Unlock HealthAppTransfer")
            withAnimation { showLockedScreen = false }
        } catch {
            // Stay locked — user can retry via button
            Loggers.security.info("Biometric unlock failed or cancelled")
        }
    }

    private func lockIfEnabled() async {
        let isBiometricEnabled = loadBiometricPreference()
        if isBiometricEnabled {
            await biometricService.lock()
            withAnimation { showLockedScreen = true }
        }
    }

    private func loadBiometricPreference() -> Bool {
        let descriptor = FetchDescriptor<UserPreferences>()
        return (try? modelContext.fetch(descriptor).first?.requireBiometricAuth) ?? false
    }

    // MARK: - HealthKit Authorization

    private func requestHealthKitAuthIfNeeded() async {
        guard !hasRequestedHealthKitAuth, HealthKitService.isAvailable else { return }
        showHealthKitAlert = true
    }

    private func authorizeHealthKit() async {
        do {
            try await healthKitService.requestAuthorization()
            hasRequestedHealthKitAuth = true
        } catch {
            Loggers.healthKit.error("HealthKit authorization failed: \(error.localizedDescription)")
            hasRequestedHealthKitAuth = true
        }
    }
}

#Preview {
    ContentView()
}
