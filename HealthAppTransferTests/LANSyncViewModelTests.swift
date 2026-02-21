import XCTest
import SwiftUI
@testable import HealthAppTransfer

// MARK: - LAN Sync ViewModel Tests

@MainActor
final class LANSyncViewModelTests: XCTestCase {

    // MARK: - ConnectionStatus Display Text

    func testDisconnectedDisplayText() {
        let status = LANSyncViewModel.ConnectionStatus.disconnected
        XCTAssertTrue(status.displayText.lowercased().contains("disconnect"))
    }

    func testSearchingDisplayText() {
        let status = LANSyncViewModel.ConnectionStatus.searching
        XCTAssertTrue(status.displayText.lowercased().contains("search"))
    }

    func testConnectingDisplayTextContainsDeviceName() {
        let status = LANSyncViewModel.ConnectionStatus.connecting("iPhone")
        XCTAssertTrue(status.displayText.contains("iPhone"))
    }

    func testConnectedDisplayTextContainsDeviceName() {
        let status = LANSyncViewModel.ConnectionStatus.connected("iPhone")
        XCTAssertTrue(status.displayText.contains("iPhone"))
    }

    func testFailedDisplayTextContainsErrorMessage() {
        let status = LANSyncViewModel.ConnectionStatus.failed("Timeout")
        XCTAssertTrue(status.displayText.contains("Timeout"))
    }

    // MARK: - ConnectionStatus System Image

    func testDisconnectedSystemImage() {
        let status = LANSyncViewModel.ConnectionStatus.disconnected
        XCTAssertEqual(status.systemImage, "wifi.slash")
    }

    func testSearchingSystemImage() {
        let status = LANSyncViewModel.ConnectionStatus.searching
        XCTAssertEqual(status.systemImage, "wifi.exclamationmark")
    }

    func testConnectingSystemImage() {
        let status = LANSyncViewModel.ConnectionStatus.connecting("iPhone")
        XCTAssertEqual(status.systemImage, "wifi")
    }

    func testConnectedSystemImage() {
        let status = LANSyncViewModel.ConnectionStatus.connected("iPhone")
        XCTAssertEqual(status.systemImage, "wifi")
    }

    func testFailedSystemImage() {
        let status = LANSyncViewModel.ConnectionStatus.failed("Error")
        XCTAssertEqual(status.systemImage, "wifi.exclamationmark")
    }

    // MARK: - ConnectionStatus Color

    func testDisconnectedColor() {
        let status = LANSyncViewModel.ConnectionStatus.disconnected
        XCTAssertEqual(status.color, .secondary)
    }

    func testSearchingColor() {
        let status = LANSyncViewModel.ConnectionStatus.searching
        XCTAssertEqual(status.color, .orange)
    }

    func testConnectingColor() {
        let status = LANSyncViewModel.ConnectionStatus.connecting("iPhone")
        XCTAssertEqual(status.color, .orange)
    }

    func testConnectedColor() {
        let status = LANSyncViewModel.ConnectionStatus.connected("iPhone")
        XCTAssertEqual(status.color, .green)
    }

    func testFailedColor() {
        let status = LANSyncViewModel.ConnectionStatus.failed("Error")
        XCTAssertEqual(status.color, .red)
    }

    // MARK: - ConnectionStatus Equatable

    func testDisconnectedEqualsDisconnected() {
        XCTAssertEqual(
            LANSyncViewModel.ConnectionStatus.disconnected,
            LANSyncViewModel.ConnectionStatus.disconnected
        )
    }

    func testSearchingEqualsSearching() {
        XCTAssertEqual(
            LANSyncViewModel.ConnectionStatus.searching,
            LANSyncViewModel.ConnectionStatus.searching
        )
    }

    func testConnectedWithSameNameAreEqual() {
        XCTAssertEqual(
            LANSyncViewModel.ConnectionStatus.connected("iPhone"),
            LANSyncViewModel.ConnectionStatus.connected("iPhone")
        )
    }

    func testConnectedWithDifferentNamesAreNotEqual() {
        XCTAssertNotEqual(
            LANSyncViewModel.ConnectionStatus.connected("A"),
            LANSyncViewModel.ConnectionStatus.connected("B")
        )
    }

    func testConnectingWithDifferentNamesAreNotEqual() {
        XCTAssertNotEqual(
            LANSyncViewModel.ConnectionStatus.connecting("A"),
            LANSyncViewModel.ConnectionStatus.connecting("B")
        )
    }

    func testFailedWithDifferentMessagesAreNotEqual() {
        XCTAssertNotEqual(
            LANSyncViewModel.ConnectionStatus.failed("Error A"),
            LANSyncViewModel.ConnectionStatus.failed("Error B")
        )
    }

    func testDifferentCasesAreNotEqual() {
        XCTAssertNotEqual(
            LANSyncViewModel.ConnectionStatus.disconnected,
            LANSyncViewModel.ConnectionStatus.searching
        )
        XCTAssertNotEqual(
            LANSyncViewModel.ConnectionStatus.connected("iPhone"),
            LANSyncViewModel.ConnectionStatus.connecting("iPhone")
        )
    }
}
