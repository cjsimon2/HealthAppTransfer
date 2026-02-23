import Combine
import CryptoKit
import Foundation
import SwiftData
import SwiftUI

// MARK: - Pairing ViewModel

@MainActor
class PairingViewModel: ObservableObject {

    // MARK: - Published State (iOS QR Display)

    @Published var qrImage: Image?
    @Published var pairingCode: String = ""
    @Published var timeRemaining: Int = 0
    @Published var isServerRunning = false
    @Published var isPreparing = false
    @Published var error: String?

    // MARK: - Published State (macOS Scan)

    @Published var scannedPayload: QRPairingPayload?
    @Published var scanError: String?
    @Published var isPairing = false
    @Published var pairingSuccess = false

    // MARK: - Dependencies

    let pairingService: PairingService
    let certificateService: CertificateService
    let networkServer: NetworkServer

    private var countdownTimer: Timer?

    init(
        pairingService: PairingService,
        certificateService: CertificateService,
        networkServer: NetworkServer
    ) {
        self.pairingService = pairingService
        self.certificateService = certificateService
        self.networkServer = networkServer
    }

    // MARK: - iOS: QR Code Display Flow

    /// Start the server and display a QR code for pairing.
    func startSharing() async {
        isPreparing = true
        error = nil

        do {
            try await networkServer.start()
            try await Task.sleep(for: .milliseconds(500))

            guard let port = await networkServer.actualPort else {
                error = "Server failed to start — no port assigned"
                isPreparing = false
                return
            }

            isServerRunning = true
            isPreparing = false

            // Advertise via Bonjour so Mac clients can discover this iPhone
            await networkServer.startBonjourAdvertisement()

            await generateQRCode(port: port)
        } catch {
            self.error = "Failed to start server: \(error.localizedDescription)"
            isPreparing = false
        }
    }

    /// Stop the server and clear the QR code.
    func stopSharing() async {
        countdownTimer?.invalidate()
        countdownTimer = nil
        await networkServer.stop()
        isServerRunning = false
        qrImage = nil
        pairingCode = ""
        timeRemaining = 0
    }

    /// Refresh the pairing code and QR code.
    func refreshCode() async {
        guard let port = await networkServer.actualPort else { return }
        await generateQRCode(port: port)
    }

    // MARK: - macOS: QR Scan Flow

    /// Try to parse a QR pairing payload from clipboard text.
    func parseClipboard(_ text: String) {
        scanError = nil
        guard let payload = QRPairingPayload.fromJSON(text) else {
            scanError = "Invalid pairing data. Copy the QR code content from the iOS device."
            return
        }
        if payload.isExpired {
            scanError = "This pairing code has expired. Generate a new one on the iOS device."
            return
        }
        scannedPayload = payload
    }

    /// Handle a QR code string detected by camera.
    func handleScannedQRCode(_ string: String) {
        parseClipboard(string)
    }

    /// Connect to the scanned server and complete pairing.
    func completePairing(modelContext: ModelContext) async {
        guard let payload = scannedPayload else { return }

        isPairing = true
        scanError = nil

        let url = "https://\(payload.host):\(payload.port)/api/v1/pair"

        #if os(macOS)
        let myDeviceName = Host.current().localizedName ?? "Mac"
        #else
        let myDeviceName = UIDevice.current.name
        #endif

        let requestBody: [String: String] = [
            "code": payload.code,
            "deviceName": myDeviceName
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody),
              let requestURL = URL(string: url) else {
            scanError = "Failed to build pairing request"
            isPairing = false
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession(
            configuration: .ephemeral,
            delegate: TLSPinningDelegate(expectedFingerprint: payload.fingerprint),
            delegateQueue: nil
        )

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                scanError = "Pairing rejected by server"
                isPairing = false
                return
            }

            let apiResponse = try JSONDecoder().decode(APIResponse<PairResponse>.self, from: data)

            guard let pairResponse = apiResponse.data else {
                scanError = "Invalid response from server"
                isPairing = false
                return
            }

            // Store paired server in SwiftData
            let device = PairedDevice(
                deviceID: pairResponse.deviceID ?? UUID().uuidString,
                name: "\(payload.host):\(payload.port)",
                platform: "iOS",
                tokenHash: tokenHash(pairResponse.token)
            )
            modelContext.insert(device)
            try modelContext.save()

            // Store the actual bearer token and TLS fingerprint in Keychain
            let keychain = KeychainStore()
            try await keychain.save(
                key: "serverToken_\(device.deviceID)",
                data: Data(pairResponse.token.utf8)
            )
            try await keychain.save(
                key: "fingerprint_\(device.deviceID)",
                data: Data(payload.fingerprint.utf8)
            )

            pairingSuccess = true
            isPairing = false
        } catch {
            scanError = "Connection failed: \(error.localizedDescription)"
            isPairing = false
        }

        session.invalidateAndCancel()
    }

    // MARK: - Device Management

    /// Revoke a paired device: remove from SwiftData and revoke the token.
    func revokeDevice(_ device: PairedDevice, modelContext: ModelContext) async {
        await pairingService.revokeDeviceToken(deviceID: device.deviceID)
        modelContext.delete(device)
        try? modelContext.save()
    }

    /// Revoke all paired devices.
    func revokeAllDevices(devices: [PairedDevice], modelContext: ModelContext) async {
        await pairingService.revokeAll()
        for device in devices {
            modelContext.delete(device)
        }
        try? modelContext.save()
    }

    // MARK: - Private Helpers

    private func generateQRCode(port: UInt16) async {
        do {
            let fingerprint = try await certificateService.tlsFingerprint()
            let pairingCodeResult = await pairingService.generatePairingCode()

            guard let host = NetworkHelpers.localIPAddress() else {
                error = "Could not determine local IP address. Ensure you're connected to WiFi."
                return
            }

            let payload = QRPairingPayload(
                host: host,
                port: port,
                fingerprint: fingerprint,
                code: pairingCodeResult.code,
                expiry: pairingCodeResult.expiresAt.timeIntervalSince1970
            )

            self.pairingCode = pairingCodeResult.code

            if let json = payload.toJSON() {
                qrImage = QRCodeRenderer.image(from: json, size: 280)
            }

            startCountdown(until: pairingCodeResult.expiresAt)
        } catch {
            self.error = "Failed to generate QR code: \(error.localizedDescription)"
        }
    }

    private func startCountdown(until expiryDate: Date) {
        countdownTimer?.invalidate()
        updateTimeRemaining(until: expiryDate)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateTimeRemaining(until: expiryDate)
                if self.timeRemaining <= 0 {
                    await self.refreshCode()
                }
            }
        }
    }

    private func updateTimeRemaining(until expiryDate: Date) {
        timeRemaining = max(0, Int(expiryDate.timeIntervalSinceNow))
    }

    private func tokenHash(_ token: String) -> String {
        let hash = SHA256.hash(data: Data(token.utf8))
        return String(hash.map { String(format: "%02x", $0) }.joined().prefix(16))
    }
}

// MARK: - TLS Pinning Delegate

/// URLSession delegate that verifies the server's TLS certificate fingerprint
/// matches the one encoded in the QR code.
final class TLSPinningDelegate: NSObject, URLSessionDelegate, Sendable {
    let expectedFingerprint: String

    init(expectedFingerprint: String) {
        self.expectedFingerprint = expectedFingerprint
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.cancelAuthenticationChallenge, nil)
        }

        guard let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let serverCert = certificates.first else {
            return (.cancelAuthenticationChallenge, nil)
        }

        let derData = SecCertificateCopyData(serverCert) as Data
        let hash = SHA256.hash(data: derData)
        let fingerprint = hash.map { String(format: "%02x", $0) }.joined()

        if fingerprint == expectedFingerprint {
            return (.useCredential, URLCredential(trust: serverTrust))
        }

        Loggers.security.warning("TLS fingerprint mismatch — expected: \(self.expectedFingerprint), got: \(fingerprint)")
        return (.cancelAuthenticationChallenge, nil)
    }
}
