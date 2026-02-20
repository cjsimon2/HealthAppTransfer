import Foundation

// MARK: - QR Pairing Payload

/// The data encoded in the QR code for device pairing.
/// Contains everything the scanning device needs to connect and authenticate.
struct QRPairingPayload: Codable, Sendable {
    let host: String
    let port: UInt16
    let fingerprint: String // SHA-256 hex of TLS certificate DER
    let code: String        // 6-digit pairing code
    let expiry: TimeInterval // Unix timestamp when code expires

    var isExpired: Bool {
        Date().timeIntervalSince1970 > expiry
    }

    var expiryDate: Date {
        Date(timeIntervalSince1970: expiry)
    }

    var timeRemaining: TimeInterval {
        max(0, expiry - Date().timeIntervalSince1970)
    }

    func toJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func fromJSON(_ string: String) -> QRPairingPayload? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(QRPairingPayload.self, from: data)
    }
}
