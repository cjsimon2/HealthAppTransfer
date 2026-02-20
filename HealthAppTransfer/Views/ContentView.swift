import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: PairingViewModel

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

        _viewModel = StateObject(wrappedValue: PairingViewModel(
            pairingService: pairingService,
            certificateService: certificateService,
            networkServer: networkServer
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PairingView(viewModel: viewModel)
                    } label: {
                        Label("Pair Device", systemImage: "qrcode")
                    }

                    NavigationLink {
                        PairedDevicesView(viewModel: viewModel)
                    } label: {
                        Label("Paired Devices", systemImage: "link")
                    }
                } header: {
                    Text("Transfer")
                }
            }
            .navigationTitle("HealthAppTransfer")
        }
        .task {
            await viewModel.pairingService.loadPersistedTokens()
        }
    }
}

#Preview {
    ContentView()
}
