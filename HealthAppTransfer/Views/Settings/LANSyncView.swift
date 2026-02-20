import SwiftData
import SwiftUI

// MARK: - LAN Sync View

/// Mac app view for discovering and syncing with an iPhone over the local network.
/// Shows connection status indicator, discovered devices, and sync controls.
struct LANSyncView: View {
    @ObservedObject var viewModel: LANSyncViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PairedDevice.pairedAt, order: .reverse) private var pairedDevices: [PairedDevice]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                connectionStatusSection
                discoveredDevicesSection
                syncSection
                if let error = viewModel.error {
                    errorBanner(error)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("LAN Sync")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            viewModel.startSearching()
        }
        .onDisappear {
            viewModel.stopSearching()
        }
    }

    // MARK: - Connection Status

    private var connectionStatusSection: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.connectionStatus.systemImage)
                .font(.system(size: 40))
                .foregroundStyle(viewModel.connectionStatus.color)
                .symbolEffect(.pulse, isActive: isPulsing)

            Text(viewModel.connectionStatus.displayText)
                .font(.title3.bold())
                .foregroundStyle(viewModel.connectionStatus.color)

            if viewModel.discovery.isSearching {
                Text("Looking for devices on your network...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var isPulsing: Bool {
        switch viewModel.connectionStatus {
        case .searching, .connecting:
            return true
        default:
            return false
        }
    }

    // MARK: - Discovered Devices

    private var discoveredDevicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Devices on Network")
                    .font(.headline)
                Spacer()
                if viewModel.discovery.isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if viewModel.discovery.discoveredDevices.isEmpty {
                emptyDeviceState
            } else {
                ForEach(viewModel.discovery.discoveredDevices) { device in
                    discoveredDeviceRow(device)
                }
            }
        }
        .padding(16)
        .background(.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyDeviceState: some View {
        VStack(spacing: 8) {
            Text("No devices found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Make sure your iPhone is on the same WiFi network and has sharing enabled.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func discoveredDeviceRow(_ device: BonjourDiscovery.DiscoveredDevice) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body.weight(.medium))

                Text("\(device.host):\(device.port)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }

            Spacer()

            connectButton(for: device)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func connectButton(for device: BonjourDiscovery.DiscoveredDevice) -> some View {
        // Find matching paired device
        if let paired = pairedDevices.first(where: { $0.isAuthorized }) {
            if case .connected = viewModel.connectionStatus {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if case .connecting = viewModel.connectionStatus {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button("Connect") {
                    Task { await viewModel.connectToDevice(device, pairedDevice: paired) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        } else {
            Text("Not Paired")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        VStack(spacing: 16) {
            if case .connected = viewModel.connectionStatus {
                Button {
                    Task { await viewModel.syncData(modelContext: modelContext) }
                } label: {
                    if viewModel.isSyncing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Syncing...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Label("Pull Health Data", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSyncing)

                if let result = viewModel.lastSyncResult {
                    lastSyncInfo(result)
                }
            }
        }
    }

    private func lastSyncInfo(_ result: LANSyncClient.SyncResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Last Sync", systemImage: "clock")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("Types:").foregroundStyle(.secondary)
                    Text("\(result.typesAvailable)")
                }
                GridRow {
                    Text("Samples:").foregroundStyle(.secondary)
                    Text("\(result.samplesFetched)")
                }
                GridRow {
                    Text("Duration:").foregroundStyle(.secondary)
                    Text(String(format: "%.1fs", result.duration))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
        }
        .padding(12)
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
