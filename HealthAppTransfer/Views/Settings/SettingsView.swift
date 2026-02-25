import SwiftUI

// MARK: - Settings View

struct SettingsView: View {

    // MARK: - Dependencies

    @ObservedObject var pairingViewModel: PairingViewModel
    @ObservedObject var lanSyncViewModel: LANSyncViewModel
    @ObservedObject var securitySettingsViewModel: SecuritySettingsViewModel
    let healthKitService: HealthKitService

    // MARK: - Body

    var body: some View {
        List {
            Section {
                NavigationLink {
                    SyncSettingsView(healthKitService: healthKitService)
                } label: {
                    settingsRow("Sync Settings", icon: "arrow.triangle.2.circlepath", color: AppColors.primary)
                }
                .accessibilityIdentifier("settings.syncSettings")
            } header: {
                Text("Sync")
            }

            Section {
                NavigationLink {
                    PairingView(viewModel: pairingViewModel)
                } label: {
                    settingsRow("Pair Device", icon: "qrcode", color: AppColors.accent)
                }
                .accessibilityIdentifier("settings.pairDevice")

                NavigationLink {
                    PairedDevicesView(viewModel: pairingViewModel)
                } label: {
                    settingsRow("Paired Devices", icon: "link", color: AppColors.secondary)
                }
                .accessibilityIdentifier("settings.pairedDevices")
            } header: {
                Text("Transfer")
            }

            Section {
                NavigationLink {
                    LANSyncView(viewModel: lanSyncViewModel)
                } label: {
                    HStack {
                        settingsIconBadge("wifi", color: AppColors.primary)
                        Text("LAN Sync")
                        Spacer()
                        connectionStatusBadge
                    }
                }
                .accessibilityLabel("LAN Sync, \(connectionStatusLabel)")
                .accessibilityIdentifier("settings.lanSync")
            } header: {
                Text("Network")
            }

            Section {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    settingsRow("Notifications", icon: "bell.badge", color: AppColors.secondary)
                }
                .accessibilityIdentifier("settings.notifications")
            } header: {
                Text("Notifications")
            }

            Section {
                NavigationLink {
                    SecuritySettingsView(viewModel: securitySettingsViewModel)
                } label: {
                    settingsRow("Security", icon: "lock.shield", color: AppColors.accent)
                }
                .accessibilityIdentifier("settings.security")
            } header: {
                Text("Security")
            }

            Section {
                HStack(spacing: 12) {
                    settingsIconBadge("info.circle", color: AppColors.textSecondary)
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("settings.version")
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
    }

    // MARK: - Settings Row

    private func settingsRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            settingsIconBadge(icon, color: color)
            Text(title)
        }
    }

    private func settingsIconBadge(_ icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 6))
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
