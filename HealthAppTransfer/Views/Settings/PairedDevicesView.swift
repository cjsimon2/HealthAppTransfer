import SwiftData
import SwiftUI

// MARK: - Paired Devices View

/// Displays a list of paired devices with the ability to revoke individual devices or all at once.
struct PairedDevicesView: View {
    @ObservedObject var viewModel: PairingViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PairedDevice.pairedAt, order: .reverse) private var devices: [PairedDevice]
    @State private var showRevokeAllConfirmation = false

    var body: some View {
        Group {
            if devices.isEmpty {
                emptyState
            } else {
                deviceList
            }
        }
        .navigationTitle("Paired Devices")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !devices.isEmpty {
                    Button("Revoke All", role: .destructive) {
                        showRevokeAllConfirmation = true
                    }
                }
            }
        }
        #endif
        .confirmationDialog(
            "Revoke All Devices",
            isPresented: $showRevokeAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Revoke All", role: .destructive) {
                Task { await viewModel.revokeAllDevices(devices: devices, modelContext: modelContext) }
            }
        } message: {
            Text("All paired devices will be disconnected and will need to pair again.")
        }
    }

    // MARK: - Device List

    private var deviceList: some View {
        List {
            Section {
                ForEach(devices) { device in
                    deviceRow(device)
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            let device = devices[index]
                            await viewModel.revokeDevice(device, modelContext: modelContext)
                        }
                    }
                }
            } header: {
                Text("\(devices.count) devices")
            } footer: {
                Text("Revoking a device disconnects it and requires re-pairing to access health data.")
            }
        }
    }

    private func deviceRow(_ device: PairedDevice) -> some View {
        HStack(spacing: 12) {
            Image(systemName: device.platform == "macOS" ? "desktopcomputer" : "iphone")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(device.name)
                        .font(.body.weight(.medium))

                    if !device.isAuthorized {
                        Text("Revoked")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Text("Paired \(device.pairedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if device.isAuthorized {
                Button(role: .destructive) {
                    Task { await viewModel.revokeDevice(device, modelContext: modelContext) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Revoke \(device.name)")
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "link.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Paired Devices")
                .font(.title3.bold())

            Text("Pair a device using the QR code to start transferring health data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}
