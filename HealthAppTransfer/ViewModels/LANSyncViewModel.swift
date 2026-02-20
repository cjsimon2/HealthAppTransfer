import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - LAN Sync ViewModel

/// Coordinates Bonjour discovery, LAN connection, and health data sync.
/// Used by the Mac app to discover and pull data from a paired iPhone on the same network.
@MainActor
class LANSyncViewModel: ObservableObject {

    // MARK: - Connection Status

    enum ConnectionStatus: Equatable {
        case disconnected
        case searching
        case connecting(String) // device name
        case connected(String)  // device name
        case failed(String)     // error message

        var displayText: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .searching: return "Searching..."
            case .connecting(let name): return "Connecting to \(name)..."
            case .connected(let name): return "Connected to \(name)"
            case .failed(let error): return "Failed: \(error)"
            }
        }

        var systemImage: String {
            switch self {
            case .disconnected: return "wifi.slash"
            case .searching: return "wifi.exclamationmark"
            case .connecting: return "wifi"
            case .connected: return "wifi"
            case .failed: return "wifi.exclamationmark"
            }
        }

        var color: Color {
            switch self {
            case .disconnected: return .secondary
            case .searching: return .orange
            case .connecting: return .orange
            case .connected: return .green
            case .failed: return .red
            }
        }
    }

    // MARK: - Published State

    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    @Published private(set) var lastSyncResult: LANSyncClient.SyncResult?
    @Published private(set) var isSyncing = false
    @Published var error: String?

    // MARK: - Dependencies

    let discovery: BonjourDiscovery
    private let syncClient: LANSyncClient
    private let keychain: KeychainStore

    private var reconnectTask: Task<Void, Never>?
    private var discoveryObserver: AnyCancellable?
    private var connectedDeviceID: String?
    private var connectedToken: String?

    init(keychain: KeychainStore) {
        self.keychain = keychain
        self.discovery = BonjourDiscovery()
        self.syncClient = LANSyncClient(keychain: keychain)
    }

    // MARK: - Discovery

    /// Start searching for iPhone servers on the local network.
    func startSearching() {
        connectionStatus = .searching
        discovery.startBrowsing()

        // Watch for discovered devices and auto-connect to paired ones
        discoveryObserver = discovery.$discoveredDevices
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] devices in
                Task { @MainActor [weak self] in
                    await self?.handleDiscoveredDevices(devices)
                }
            }
    }

    /// Stop searching and disconnect.
    func stopSearching() {
        reconnectTask?.cancel()
        reconnectTask = nil
        discoveryObserver?.cancel()
        discoveryObserver = nil
        discovery.stopBrowsing()
        Task { await syncClient.disconnect() }
        connectionStatus = .disconnected
        connectedDeviceID = nil
        connectedToken = nil
    }

    // MARK: - Connection

    /// Manually connect to a specific discovered device.
    func connectToDevice(_ device: BonjourDiscovery.DiscoveredDevice, pairedDevice: PairedDevice) async {
        connectionStatus = .connecting(device.name)
        error = nil

        do {
            let token = try await syncClient.loadToken(for: pairedDevice.deviceID)

            // We need the TLS fingerprint — load it from keychain
            guard let fingerprintData = try await keychain.load(key: "fingerprint_\(pairedDevice.deviceID)"),
                  let fingerprint = String(data: fingerprintData, encoding: .utf8) else {
                connectionStatus = .failed("Missing TLS fingerprint — re-pair required")
                return
            }

            let success = await syncClient.connect(
                host: device.host,
                port: device.port,
                fingerprint: fingerprint,
                token: token
            )

            if success {
                connectionStatus = .connected(device.name)
                connectedDeviceID = pairedDevice.deviceID
                connectedToken = token

                // Update last seen
                pairedDevice.lastSeenAt = Date()
                pairedDevice.lastIPAddress = device.host
            } else {
                connectionStatus = .failed("Could not connect to \(device.name)")
            }
        } catch {
            connectionStatus = .failed(error.localizedDescription)
            self.error = error.localizedDescription
        }
    }

    // MARK: - Data Sync

    /// Pull health data from the connected iPhone.
    func syncData() async {
        guard let token = connectedToken else {
            error = "Not connected"
            return
        }

        isSyncing = true
        error = nil

        do {
            let result = try await syncClient.pullAllData(token: token)
            lastSyncResult = result
            isSyncing = false
        } catch {
            self.error = "Sync failed: \(error.localizedDescription)"
            isSyncing = false

            // If connection lost, update status
            let clientState = await syncClient.state
            if case .failed = clientState {
                connectionStatus = .disconnected
                startAutoReconnect()
            }
        }
    }

    // MARK: - Auto-Reconnect

    /// Start attempting to reconnect when the connection drops.
    private func startAutoReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }

                guard let self else { return }
                // If we reconnected already, stop
                if case .connected = self.connectionStatus { return }

                // Check if the device reappeared in discovery
                if !self.discovery.discoveredDevices.isEmpty {
                    await self.handleDiscoveredDevices(self.discovery.discoveredDevices)
                }
            }
        }
    }

    // MARK: - Private

    private func handleDiscoveredDevices(_ devices: [BonjourDiscovery.DiscoveredDevice]) async {
        // Only auto-connect if we're searching (not already connected)
        guard case .searching = connectionStatus else { return }
        guard !devices.isEmpty else { return }

        // Auto-connect logic would match discovered devices against paired devices
        // For now, just update the status to show devices are available
        Loggers.network.info("LANSync: found \(devices.count) device(s) on network")
    }
}
