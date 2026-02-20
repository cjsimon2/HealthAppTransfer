import Foundation
import SwiftData

// MARK: - Paired Device

/// A device that has been paired for health data transfer.
@Model
final class PairedDevice {

    // MARK: - Properties

    /// Unique identifier for this paired device.
    @Attribute(.unique) var deviceID: String

    /// Human-readable device name (e.g., "Casey's MacBook Pro").
    var name: String

    /// Platform: "iOS" or "macOS".
    var platform: String

    /// Whether this device is currently authorized for data access.
    var isAuthorized: Bool = true

    /// The hashed bearer token for this device's API access.
    var tokenHash: String?

    /// When the device was first paired.
    var pairedAt: Date = Date()

    /// When the device last connected.
    var lastSeenAt: Date?

    /// IP address of last connection.
    var lastIPAddress: String?

    // MARK: - Init

    init(
        deviceID: String,
        name: String,
        platform: String,
        tokenHash: String? = nil
    ) {
        self.deviceID = deviceID
        self.name = name
        self.platform = platform
        self.tokenHash = tokenHash
        self.isAuthorized = true
        self.pairedAt = Date()
    }
}
