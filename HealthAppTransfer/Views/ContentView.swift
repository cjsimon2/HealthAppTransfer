import SwiftUI
import SwiftData

// MARK: - Content View

/// Root view that delegates to MainTabView.
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
    @State private var hasCompletedOnboarding = false

    // MARK: - Services

    private let services: ServiceContainer

    // MARK: - Init

    init(services: ServiceContainer = ServiceContainer()) {
        self.services = services
        _pairingViewModel = StateObject(wrappedValue: services.makePairingViewModel())
        _lanSyncViewModel = StateObject(wrappedValue: services.makeLANSyncViewModel())
        _securitySettingsViewModel = StateObject(wrappedValue: services.makeSecuritySettingsViewModel())
    }

    // MARK: - Body

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainContent
            } else {
                OnboardingView(healthKitService: services.healthKitService) {
                    withAnimation { hasCompletedOnboarding = true }
                }
            }
        }
        .onAppear { loadOnboardingState() }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            MainTabView(
                pairingViewModel: pairingViewModel,
                lanSyncViewModel: lanSyncViewModel,
                healthKitService: services.healthKitService,
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
                    Label("Unlock with \(services.biometricService.biometricName)", systemImage: securitySettingsViewModel.biometricIconName)
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
            await services.biometricService.unlockWithoutAuth()
        }
    }

    private func authenticateToUnlock() async {
        do {
            try await services.biometricService.authenticate(reason: "Unlock HealthAppTransfer")
            withAnimation { showLockedScreen = false }
        } catch {
            // Stay locked — user can retry via button
            Loggers.security.info("Biometric unlock failed or cancelled")
        }
    }

    private func lockIfEnabled() async {
        let isBiometricEnabled = loadBiometricPreference()
        if isBiometricEnabled {
            await services.biometricService.lock()
            withAnimation { showLockedScreen = true }
        }
    }

    private func loadBiometricPreference() -> Bool {
        let descriptor = FetchDescriptor<UserPreferences>()
        return (try? modelContext.fetch(descriptor).first?.requireBiometricAuth) ?? false
    }

    // MARK: - Onboarding

    private func loadOnboardingState() {
        let descriptor = FetchDescriptor<UserPreferences>()
        hasCompletedOnboarding = (try? modelContext.fetch(descriptor).first?.hasCompletedOnboarding) ?? false
    }

    // MARK: - HealthKit Authorization

    private func requestHealthKitAuthIfNeeded() async {
        guard !hasRequestedHealthKitAuth, HealthKitService.isAvailable else { return }
        showHealthKitAlert = true
    }

    private func authorizeHealthKit() async {
        do {
            try await services.healthKitService.requestAuthorization()
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
