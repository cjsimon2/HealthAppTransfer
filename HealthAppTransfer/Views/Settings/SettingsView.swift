import SwiftUI

// MARK: - Settings View

struct SettingsView: View {

    // MARK: - Observed Objects

    @ObservedObject var pairingViewModel: PairingViewModel
    @ObservedObject var lanSyncViewModel: LANSyncViewModel
    @ObservedObject var securitySettingsViewModel: SecuritySettingsViewModel

    // MARK: - Body

    var body: some View {
        List {
            Section {
                NavigationLink {
                    PairingView(viewModel: pairingViewModel)
                } label: {
                    Label("Pair Device", systemImage: "qrcode")
                }

                NavigationLink {
                    PairedDevicesView(viewModel: pairingViewModel)
                } label: {
                    Label("Paired Devices", systemImage: "link")
                }
            } header: {
                Text("Transfer")
            }

            Section {
                NavigationLink {
                    LANSyncView(viewModel: lanSyncViewModel)
                } label: {
                    Label {
                        HStack {
                            Text("LAN Sync")
                            Spacer()
                            connectionStatusBadge
                        }
                    } icon: {
                        Image(systemName: "wifi")
                    }
                }
            } header: {
                Text("Network")
            }

            Section {
                NavigationLink {
                    SecuritySettingsView(viewModel: securitySettingsViewModel)
                } label: {
                    Label("Security", systemImage: "lock.shield")
                }
            } header: {
                Text("Security")
            }

            Section {
                Label("Version 1.0.0", systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
    }

    // MARK: - Helpers

    @ViewBuilder
    private var connectionStatusBadge: some View {
        switch lanSyncViewModel.connectionStatus {
        case .connected:
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        case .searching, .connecting:
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
        case .failed:
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        case .disconnected:
            EmptyView()
        }
    }
}
