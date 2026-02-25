import Foundation
import UserNotifications

// MARK: - Notification Center Protocol

/// Abstraction over UNUserNotificationCenter for testability.
protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func isAuthorized() async -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

// MARK: - UNUserNotificationCenter Conformance

extension UNUserNotificationCenter: NotificationCenterProtocol {
    func isAuthorized() async -> Bool {
        let settings = await notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}

// MARK: - Notification Service

/// Manages local push notifications for streak alerts and goal progress.
/// Conservative: once per day max per notification type via 24-hour cooldown.
actor NotificationService {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Properties

    private let center: any NotificationCenterProtocol
    private let defaults: UserDefaults
    static let cooldownKey = "notification_cooldowns"

    // MARK: - Init

    init(center: any NotificationCenterProtocol = UNUserNotificationCenter.current(), defaults: UserDefaults = .standard) {
        self.center = center
        self.defaults = defaults
    }

    // MARK: - Streak Alert

    func scheduleStreakAlert(type: HealthDataType, streakDays: Int) async {
        guard await center.isAuthorized() else { return }

        let identifier = "streak.\(type.rawValue)"
        guard !isWithinCooldown(identifier: identifier) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk!"
        content.body = "Your \(streakDays)-day \(type.displayName.lowercased()) streak needs activity today."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
        recordCooldown(identifier: identifier)
    }

    // MARK: - Goal Nearly Met

    func scheduleGoalNearlyMet(type: HealthDataType, current: Double, goal: Double, unit: String) async {
        guard await center.isAuthorized() else { return }

        let identifier = "goal.\(type.rawValue)"
        guard !isWithinCooldown(identifier: identifier) else { return }

        let pct = Int((current / goal) * 100)
        let content = UNMutableNotificationContent()
        content.title = "Almost There!"
        content.body = "\(type.displayName) is at \(pct)% — just \(Int(goal - current)) \(unit) to go."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
        recordCooldown(identifier: identifier)
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // MARK: - Cooldown (24-hour deduplication)

    func isWithinCooldown(identifier: String) -> Bool {
        guard let cooldowns = defaults.dictionary(forKey: Self.cooldownKey) as? [String: Double] else {
            return false
        }
        guard let lastFired = cooldowns[identifier] else { return false }
        let lastDate = Date(timeIntervalSince1970: lastFired)
        return Date().timeIntervalSince(lastDate) < 86400
    }

    func recordCooldown(identifier: String) {
        var cooldowns = defaults.dictionary(forKey: Self.cooldownKey) as? [String: Double] ?? [:]
        cooldowns[identifier] = Date().timeIntervalSince1970
        defaults.set(cooldowns, forKey: Self.cooldownKey)
    }
}
