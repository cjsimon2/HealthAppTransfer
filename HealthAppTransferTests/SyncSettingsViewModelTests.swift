import XCTest
@testable import HealthAppTransfer

// MARK: - Sync Settings ViewModel Tests

@MainActor
final class SyncSettingsViewModelTests: XCTestCase {

    // MARK: - SyncFrequency Display Names

    func testSyncFrequencyDisplayNames() {
        XCTAssertEqual(SyncFrequency.fifteenMinutes.displayName, "Every 15 min")
        XCTAssertEqual(SyncFrequency.thirtyMinutes.displayName, "Every 30 min")
        XCTAssertEqual(SyncFrequency.oneHour.displayName, "Every hour")
        XCTAssertEqual(SyncFrequency.fourHours.displayName, "Every 4 hours")
        XCTAssertEqual(SyncFrequency.daily.displayName, "Daily")
        XCTAssertEqual(SyncFrequency.manualOnly.displayName, "Manual only")
    }

    // MARK: - SyncFrequency Raw Values

    func testSyncFrequencyRawValues() {
        XCTAssertEqual(SyncFrequency.fifteenMinutes.rawValue, 900)
        XCTAssertEqual(SyncFrequency.thirtyMinutes.rawValue, 1800)
        XCTAssertEqual(SyncFrequency.oneHour.rawValue, 3600)
        XCTAssertEqual(SyncFrequency.fourHours.rawValue, 14400)
        XCTAssertEqual(SyncFrequency.daily.rawValue, 86400)
        XCTAssertEqual(SyncFrequency.manualOnly.rawValue, 0)
    }

    func testSyncFrequencyAllCasesCount() {
        XCTAssertEqual(SyncFrequency.allCases.count, 6)
    }

    func testSyncFrequencyIdentifiable() {
        let freq = SyncFrequency.oneHour
        XCTAssertEqual(freq.id, freq.rawValue)
    }

    // MARK: - SyncHistoryEntry Init

    func testSyncHistoryEntryInitSetsUUID() {
        let entry = SyncHistoryEntry(source: "manual", sampleCount: 10, success: true)
        XCTAssertNotNil(entry.id)
    }

    func testSyncHistoryEntryInitSetsDate() {
        let before = Date()
        let entry = SyncHistoryEntry(source: "manual", sampleCount: 5, success: true)
        let after = Date()
        XCTAssertGreaterThanOrEqual(entry.date, before)
        XCTAssertLessThanOrEqual(entry.date, after)
    }

    func testSyncHistoryEntryInitSetsSuccessFlag() {
        let success = SyncHistoryEntry(source: "manual", sampleCount: 10, success: true)
        XCTAssertTrue(success.success)

        let failure = SyncHistoryEntry(source: "manual", sampleCount: 0, success: false, errorMessage: "fail")
        XCTAssertFalse(failure.success)
        XCTAssertEqual(failure.errorMessage, "fail")
    }

    // MARK: - SyncHistoryEntry Codable

    func testSyncHistoryEntryCodableRoundtrip() throws {
        let entry = SyncHistoryEntry(
            date: Date(timeIntervalSince1970: 1700000000),
            source: "cloudkit",
            sampleCount: 42,
            success: true,
            errorMessage: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SyncHistoryEntry.self, from: data)

        XCTAssertEqual(decoded.id, entry.id)
        XCTAssertEqual(decoded.source, "cloudkit")
        XCTAssertEqual(decoded.sampleCount, 42)
        XCTAssertTrue(decoded.success)
        XCTAssertNil(decoded.errorMessage)
    }

    // MARK: - SyncHistoryEntry Source Display Name

    func testSourceDisplayNameForKnownSources() {
        XCTAssertEqual(
            SyncHistoryEntry(source: "manual", sampleCount: 0, success: true).sourceDisplayName,
            "Manual"
        )
        XCTAssertEqual(
            SyncHistoryEntry(source: "background", sampleCount: 0, success: true).sourceDisplayName,
            "Background"
        )
        XCTAssertEqual(
            SyncHistoryEntry(source: "cloudkit", sampleCount: 0, success: true).sourceDisplayName,
            "CloudKit"
        )
        XCTAssertEqual(
            SyncHistoryEntry(source: "lan", sampleCount: 0, success: true).sourceDisplayName,
            "LAN"
        )
    }

    func testSourceDisplayNameForUnknownSourceCapitalizes() {
        let entry = SyncHistoryEntry(source: "bluetooth", sampleCount: 0, success: true)
        XCTAssertEqual(entry.sourceDisplayName, "Bluetooth")
    }

    // MARK: - SyncHistoryEntry Source Icon

    func testSourceIconForKnownSources() {
        XCTAssertEqual(
            SyncHistoryEntry(source: "manual", sampleCount: 0, success: true).sourceIcon,
            "hand.tap"
        )
        XCTAssertEqual(
            SyncHistoryEntry(source: "background", sampleCount: 0, success: true).sourceIcon,
            "clock.arrow.circlepath"
        )
        XCTAssertEqual(
            SyncHistoryEntry(source: "cloudkit", sampleCount: 0, success: true).sourceIcon,
            "icloud"
        )
        XCTAssertEqual(
            SyncHistoryEntry(source: "lan", sampleCount: 0, success: true).sourceIcon,
            "wifi"
        )
    }

    func testSourceIconForUnknownSourceReturnsFallback() {
        let entry = SyncHistoryEntry(source: "unknown", sampleCount: 0, success: true)
        XCTAssertEqual(entry.sourceIcon, "arrow.triangle.2.circlepath")
    }

    // MARK: - ViewModel Initial State

    func testViewModelInitialStateIsSyncingFalse() {
        let store = MockHealthStore()
        let service = HealthKitService(store: store)
        let vm = SyncSettingsViewModel(healthKitService: service)

        XCTAssertFalse(vm.isSyncing)
    }

    func testViewModelInitialStateSyncHistoryEmpty() {
        let store = MockHealthStore()
        let service = HealthKitService(store: store)
        let vm = SyncSettingsViewModel(healthKitService: service)

        XCTAssertTrue(vm.syncHistory.isEmpty)
    }

    func testViewModelInitialStateErrorNil() {
        let store = MockHealthStore()
        let service = HealthKitService(store: store)
        let vm = SyncSettingsViewModel(healthKitService: service)

        XCTAssertNil(vm.error)
    }
}
