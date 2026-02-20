import SwiftUI

// MARK: - Content View

/// Root view that creates services and delegates to MainTabView.
/// Handles HealthKit authorization on first launch.
struct ContentView: View {

    // MARK: - State

    @StateObject private var pairingViewModel: PairingViewModel
    @StateObject private var lanSyncViewModel: LANSyncViewModel
    @AppStorage("hasRequestedHealthKitAuth") private var hasRequestedHealthKitAuth = false
    @State private var showHealthKitAlert = false

    // MARK: - Services

    private let healthKitService: HealthKitService

    // MARK: - Init

    init() {
        let keychain = KeychainStore()
        let certificateService = CertificateService(keychain: keychain)
        let pairingService = PairingService(keychain: keychain)
        let auditService = AuditService()
        let healthKitService = HealthKitService()

        let networkServer = NetworkServer(
            healthKitService: healthKitService,
            pairingService: pairingService,
            auditService: auditService,
            certificateService: certificateService
        )

        self.healthKitService = healthKitService

        _pairingViewModel = StateObject(wrappedValue: PairingViewModel(
            pairingService: pairingService,
            certificateService: certificateService,
            networkServer: networkServer
        ))

        _lanSyncViewModel = StateObject(wrappedValue: LANSyncViewModel(keychain: keychain))
    }

    // MARK: - Body

    var body: some View {
        MainTabView(
            pairingViewModel: pairingViewModel,
            lanSyncViewModel: lanSyncViewModel,
            healthKitService: healthKitService
        )
        .task {
            await pairingViewModel.pairingService.loadPersistedTokens()
            await requestHealthKitAuthIfNeeded()
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
