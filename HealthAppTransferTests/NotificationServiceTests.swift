import UserNotifications
import XCTest
@testable import HealthAppTransfer

final class NotificationServiceTests: XCTestCase {

    private var mockCenter: MockNotificationCenter!
    private var defaults: UserDefaults!
    private var service: NotificationService!

    override func setUp() {
        super.setUp()
        mockCenter = MockNotificationCenter()
        defaults = UserDefaults(suiteName: "NotificationServiceTests")!
        defaults.removePersistentDomain(forName: "NotificationServiceTests")
        service = NotificationService(center: mockCenter, defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "NotificationServiceTests")
        super.tearDown()
    }

    // MARK: - Streak Alert

    func testScheduleStreakAlertSendsNotification() async {
        await service.scheduleStreakAlert(type: .stepCount, streakDays: 5)

        XCTAssertEqual(mockCenter.addedRequests.count, 1)
        let request = mockCenter.addedRequests[0]
        XCTAssertEqual(request.identifier, "streak.stepCount")
        XCTAssertEqual(request.content.title, "Streak at Risk!")
        XCTAssertTrue(request.content.body.contains("5-day"))
        XCTAssertTrue(request.content.body.contains("step count"))
    }

    func testScheduleStreakAlertSkipsWhenUnauthorized() async {
        mockCenter.authorized = false

        await service.scheduleStreakAlert(type: .stepCount, streakDays: 5)

        XCTAssertTrue(mockCenter.addedRequests.isEmpty)
    }

    func testScheduleStreakAlertSkipsWhenWithinCooldown() async {
        // First call succeeds
        await service.scheduleStreakAlert(type: .stepCount, streakDays: 5)
        XCTAssertEqual(mockCenter.addedRequests.count, 1)

        // Second call within 24h is blocked
        await service.scheduleStreakAlert(type: .stepCount, streakDays: 5)
        XCTAssertEqual(mockCenter.addedRequests.count, 1)
    }

    func testScheduleStreakAlertDifferentTypesAreIndependent() async {
        await service.scheduleStreakAlert(type: .stepCount, streakDays: 5)
        await service.scheduleStreakAlert(type: .activeEnergyBurned, streakDays: 3)

        XCTAssertEqual(mockCenter.addedRequests.count, 2)
        XCTAssertEqual(mockCenter.addedRequests[0].identifier, "streak.stepCount")
        XCTAssertEqual(mockCenter.addedRequests[1].identifier, "streak.activeEnergyBurned")
    }

    // MARK: - Goal Nearly Met

    func testScheduleGoalNearlyMetSendsNotification() async {
        await service.scheduleGoalNearlyMet(type: .stepCount, current: 7500, goal: 10_000, unit: "steps")

        XCTAssertEqual(mockCenter.addedRequests.count, 1)
        let request = mockCenter.addedRequests[0]
        XCTAssertEqual(request.identifier, "goal.stepCount")
        XCTAssertEqual(request.content.title, "Almost There!")
        XCTAssertTrue(request.content.body.contains("75%"))
        XCTAssertTrue(request.content.body.contains("2500 steps"))
    }

    func testScheduleGoalNearlyMetSkipsWhenUnauthorized() async {
        mockCenter.authorized = false

        await service.scheduleGoalNearlyMet(type: .stepCount, current: 7500, goal: 10_000, unit: "steps")

        XCTAssertTrue(mockCenter.addedRequests.isEmpty)
    }

    func testScheduleGoalNearlyMetSkipsWhenWithinCooldown() async {
        await service.scheduleGoalNearlyMet(type: .stepCount, current: 7500, goal: 10_000, unit: "steps")
        XCTAssertEqual(mockCenter.addedRequests.count, 1)

        await service.scheduleGoalNearlyMet(type: .stepCount, current: 8000, goal: 10_000, unit: "steps")
        XCTAssertEqual(mockCenter.addedRequests.count, 1)
    }

    func testGoalAndStreakCooldownsAreIndependent() async {
        await service.scheduleStreakAlert(type: .stepCount, streakDays: 5)
        await service.scheduleGoalNearlyMet(type: .stepCount, current: 7500, goal: 10_000, unit: "steps")

        XCTAssertEqual(mockCenter.addedRequests.count, 2)
    }

    // MARK: - Authorization

    func testRequestAuthorizationReturnsTrueWhenGranted() async {
        mockCenter.authorized = true

        let result = await service.requestAuthorization()

        XCTAssertTrue(result)
        XCTAssertTrue(mockCenter.authorizationRequested)
    }

    func testRequestAuthorizationReturnsFalseWhenDenied() async {
        mockCenter.shouldThrowOnAuth = true

        let result = await service.requestAuthorization()

        XCTAssertFalse(result)
    }

    // MARK: - Cooldown Logic

    func testIsWithinCooldownFalseWhenNoCooldownsExist() async {
        let result = await service.isWithinCooldown(identifier: "test.id")
        XCTAssertFalse(result)
    }

    func testIsWithinCooldownTrueAfterRecording() async {
        await service.recordCooldown(identifier: "test.id")

        let result = await service.isWithinCooldown(identifier: "test.id")
        XCTAssertTrue(result)
    }

    func testIsWithinCooldownFalseForDifferentIdentifier() async {
        await service.recordCooldown(identifier: "test.a")

        let result = await service.isWithinCooldown(identifier: "test.b")
        XCTAssertFalse(result)
    }

    func testIsWithinCooldownFalseAfter24Hours() async {
        // Manually set a cooldown timestamp 25 hours in the past
        let pastTimestamp = Date().timeIntervalSince1970 - (25 * 3600)
        defaults.set(["test.expired": pastTimestamp], forKey: NotificationService.cooldownKey)

        let result = await service.isWithinCooldown(identifier: "test.expired")
        XCTAssertFalse(result)
    }

    func testRecordCooldownPreservesExistingEntries() async {
        await service.recordCooldown(identifier: "first")
        await service.recordCooldown(identifier: "second")

        let cooldowns = defaults.dictionary(forKey: NotificationService.cooldownKey) as? [String: Double]
        XCTAssertNotNil(cooldowns?["first"])
        XCTAssertNotNil(cooldowns?["second"])
    }
}

// MARK: - Mock Notification Center

private final class MockNotificationCenter: NotificationCenterProtocol, @unchecked Sendable {
    var authorized = true
    var authorizationRequested = false
    var shouldThrowOnAuth = false
    var addedRequests: [UNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authorizationRequested = true
        if shouldThrowOnAuth {
            throw NSError(domain: "MockNotificationCenter", code: -1)
        }
        return authorized
    }

    func isAuthorized() async -> Bool {
        authorized
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }
}
