import Foundation
import Network
import Combine

// MARK: - Bonjour Discovery

/// Discovers iPhone health sync servers on the local network via Bonjour (_healthsync._tcp).
/// Used by the Mac app to find and connect to paired iPhones without manual IP entry.
@MainActor
class BonjourDiscovery: ObservableObject {

    // MARK: - Types

    struct DiscoveredDevice: Identifiable, Equatable, Hashable {
        let id: String // Bonjour name
        let name: String
        let host: String
        let port: UInt16
        var lastSeen: Date

        static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    // MARK: - Published State

    @Published private(set) var discoveredDevices: [DiscoveredDevice] = []
    @Published private(set) var isSearching = false

    // MARK: - Private

    private var browser: NWBrowser?
    private let serviceType = "_healthsync._tcp"

    // MARK: - Discovery Lifecycle

    /// Start browsing for health sync services on the local network.
    func startBrowsing() {
        guard browser == nil else { return }

        let params = NWParameters()
        params.includePeerToPeer = true

        let descriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: nil)
        let newBrowser = NWBrowser(for: descriptor, using: params)

        newBrowser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.handleBrowserState(state)
            }
        }

        newBrowser.browseResultsChangedHandler = { [weak self] results, changes in
            Task { @MainActor [weak self] in
                self?.handleResultsChanged(results, changes: changes)
            }
        }

        browser = newBrowser
        newBrowser.start(queue: .main)
        isSearching = true
        Loggers.network.info("Bonjour: started browsing for \(self.serviceType)")
    }

    /// Stop browsing.
    func stopBrowsing() {
        browser?.cancel()
        browser = nil
        isSearching = false
        discoveredDevices.removeAll()
        Loggers.network.info("Bonjour: stopped browsing")
    }

    // MARK: - State Handlers

    private func handleBrowserState(_ state: NWBrowser.State) {
        switch state {
        case .ready:
            isSearching = true
            Loggers.network.info("Bonjour: browser ready")

        case .failed(let error):
            isSearching = false
            Loggers.network.error("Bonjour: browser failed — \(error.localizedDescription)")
            // Auto-restart after brief delay
            browser?.cancel()
            browser = nil
            Task {
                try? await Task.sleep(for: .seconds(3))
                startBrowsing()
            }

        case .cancelled:
            isSearching = false

        default:
            break
        }
    }

    private func handleResultsChanged(_ results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
        for change in changes {
            switch change {
            case .added(let result):
                resolveEndpoint(result)

            case .removed(let result):
                removeDevice(for: result)

            case .changed(old: _, new: let result, flags: _):
                resolveEndpoint(result)

            case .identical:
                break

            @unknown default:
                break
            }
        }
    }

    // MARK: - Endpoint Resolution

    private func resolveEndpoint(_ result: NWBrowser.Result) {
        let serviceName: String
        if case .service(let name, _, _, _) = result.endpoint {
            serviceName = name
        } else {
            return
        }

        // Use NWConnection to resolve the endpoint to host + port
        let connection = NWConnection(to: result.endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .ready = state {
                    if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                       case .hostPort(let host, let port) = innerEndpoint {
                        let hostString: String
                        switch host {
                        case .ipv4(let addr):
                            hostString = "\(addr)"
                        case .ipv6(let addr):
                            hostString = "\(addr)"
                        case .name(let name, _):
                            hostString = name
                        @unknown default:
                            hostString = "\(host)"
                        }

                        let device = DiscoveredDevice(
                            id: serviceName,
                            name: serviceName,
                            host: hostString,
                            port: port.rawValue,
                            lastSeen: Date()
                        )

                        if let index = self.discoveredDevices.firstIndex(where: { $0.id == serviceName }) {
                            self.discoveredDevices[index] = device
                        } else {
                            self.discoveredDevices.append(device)
                        }

                        Loggers.network.info("Bonjour: resolved \(serviceName) → \(hostString):\(port.rawValue)")
                    }
                    connection.cancel()
                }
            }
        }
        connection.start(queue: .main)

        // Cancel after timeout
        Task {
            try? await Task.sleep(for: .seconds(5))
            connection.cancel()
        }
    }

    private func removeDevice(for result: NWBrowser.Result) {
        if case .service(let name, _, _, _) = result.endpoint {
            discoveredDevices.removeAll { $0.id == name }
            Loggers.network.info("Bonjour: removed \(name)")
        }
    }
}
