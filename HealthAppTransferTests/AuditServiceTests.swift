import XCTest
@testable import HealthAppTransfer

final class AuditServiceTests: XCTestCase {

    // MARK: - Properties

    private var sut: AuditService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        sut = AuditService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Log & Query

    func testLogEventAddsEntry() async {
        await sut.log(event: .pairingSucceeded)

        let entries = await sut.allEntries
        XCTAssertEqual(entries.count, 1)
        XCTAssertFalse(entries[0].description.isEmpty)
    }

    func testAllEntriesReturnsLoggedEvents() async {
        await sut.log(event: .serverStarted(port: 8080))
        await sut.log(event: .serverStopped)

        let entries = await sut.allEntries
        XCTAssertEqual(entries.count, 2)
    }

    func testRecentEntriesReturnsLastN() async {
        for i in 0..<10 {
            await sut.log(event: .custom(category: "test", message: "event \(i)"))
        }

        let recent = await sut.recentEntries(count: 3)
        XCTAssertEqual(recent.count, 3)
        XCTAssertTrue(recent[2].description.contains("event 9"))
    }

    func testClearRemovesAllEntries() async {
        await sut.log(event: .pairingSucceeded)
        await sut.log(event: .serverStopped)
        await sut.clear()

        let entries = await sut.allEntries
        XCTAssertTrue(entries.isEmpty)
    }

    // MARK: - Max Entries Limit

    func testMaxEntriesLimitTruncatesOldest() async {
        for i in 0..<1001 {
            await sut.log(event: .custom(category: "test", message: "event \(i)"))
        }

        let entries = await sut.allEntries
        XCTAssertEqual(entries.count, 1000)
        // Oldest (event 0) should have been removed; first entry should be event 1
        XCTAssertTrue(entries[0].description.contains("event 1"))
    }

    // MARK: - Event Descriptions

    func testAllEventCasesProduceNonEmptyDescription() async {
        let events: [AuditService.AuditEvent] = [
            .requestReceived(method: "GET", path: "/health"),
            .pairingSucceeded,
            .pairingFailed(reason: "timeout"),
            .dataAccessed(type: "stepCount", count: 100),
            .serverStarted(port: 443),
            .serverStopped,
            .authorizationGranted,
            .authorizationDenied,
            .tokenRevoked,
            .custom(category: "test", message: "hello")
        ]

        for event in events {
            await sut.log(event: event)
        }

        let entries = await sut.allEntries
        XCTAssertEqual(entries.count, events.count)

        for entry in entries {
            XCTAssertFalse(entry.description.isEmpty, "Event description should not be empty")
        }
    }

    func testRequestReceivedDescription() async {
        await sut.log(event: .requestReceived(method: "POST", path: "/api/data"))

        let entries = await sut.allEntries
        XCTAssertTrue(entries[0].description.contains("POST"))
        XCTAssertTrue(entries[0].description.contains("/api/data"))
    }

    func testEntryTimestampIsRecent() async {
        let before = Date()
        await sut.log(event: .pairingSucceeded)
        let after = Date()

        let entries = await sut.allEntries
        XCTAssertGreaterThanOrEqual(entries[0].timestamp, before)
        XCTAssertLessThanOrEqual(entries[0].timestamp, after)
    }
}
