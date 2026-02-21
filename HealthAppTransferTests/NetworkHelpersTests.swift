import XCTest
@testable import HealthAppTransfer

final class NetworkHelpersTests: XCTestCase {

    // MARK: - localIPAddress

    func testLocalIPAddressReturnsNilOrValidIPv4() {
        let address = NetworkHelpers.localIPAddress()

        if let address {
            // If an address is returned, it should match IPv4 format
            let pattern = #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"#
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(address.startIndex..., in: address)
            let match = regex?.firstMatch(in: address, range: range)
            XCTAssertNotNil(match, "Address '\(address)' does not match IPv4 pattern")
        }
        // nil is also a valid result (no WiFi interface)
    }
}
