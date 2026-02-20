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
                .accessibilityIdentifier("settings.pairDevice")

                NavigationLink {
                    PairedDevicesView(viewModel: pairingViewModel)
                } label: {
                    Label("Paired Devices", systemImage: "link")
                }
                .accessibilityIdentifier("settings.pairedDevices")
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
                .accessibilityLabel("LAN Sync, \(connectionStatusLabel)")
                .accessibilityIdentifier("settings.lanSync")
            } header: {
                Text("Network")
            }

            Section {
                NavigationLink {
                    SecuritySettingsView(viewModel: securitySettingsViewModel)
                } label: {
                    Label("Security", systemImage: "lock.shield")
                }
                .accessibilityIdentifier("settings.security")
            } header: {
                Text("Security")
            }

            Section {
                Label("Version 1.0.0", systemImage: "info.circle")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("settings.version")
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
                .accessibilityHidden(true)
        case .searching, .connecting:
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
        case .failed:
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
                .accessibilityHidden(true)
        case .disconnected:
            EmptyView()
        }
    }

    private var connectionStatusLabel: String {
        switch lanSyncViewModel.connectionStatus {
        case .connected: "connected"
        case .searching: "searching"
        case .connecting: "connecting"
        case .failed: "connection failed"
        case .disconnected: "disconnected"
        }
    }
}
