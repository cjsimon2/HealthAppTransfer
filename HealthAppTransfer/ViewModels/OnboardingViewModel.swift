import Foundation
import SwiftData
import UserNotifications

// MARK: - Onboarding ViewModel

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Types

    enum Step: Int, CaseIterable {
        case welcome
        case healthKit
        case notifications
        case quickSetup

        #if os(macOS)
        static var activeSteps: [Step] { [.welcome, .healthKit, .quickSetup] }
        #else
        static var activeSteps: [Step] { allCases }
        #endif
    }

    struct DashboardMetric: Identifiable {
        let category: HealthDataCategory
        var isSelected: Bool = false
        var id: String { category.rawValue }
    }

    // MARK: - Published State

    @Published var currentStep: Step = .welcome
    @Published var metrics: [DashboardMetric] = []
    @Published var syncEnabled: Bool = true
    @Published var healthKitAuthorized = false
    @Published var notificationsAuthorized = false
    @Published var isRequestingHealthKit = false
    @Published var isRequestingNotifications = false

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    // MARK: - Computed

    var activeSteps: [Step] { Step.activeSteps }

    var currentStepIndex: Int {
        activeSteps.firstIndex(of: currentStep) ?? 0
    }

    var isLastStep: Bool {
        currentStep == activeSteps.last
    }

    var selectedMetricCount: Int {
        metrics.filter(\.isSelected).count
    }

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
        self.metrics = Self.defaultMetrics()
    }

    // MARK: - Navigation

    func nextStep() {
        guard let idx = activeSteps.firstIndex(of: currentStep),
              idx + 1 < activeSteps.count else { return }
        currentStep = activeSteps[idx + 1]
    }

    func previousStep() {
        guard let idx = activeSteps.firstIndex(of: currentStep),
              idx > 0 else { return }
        currentStep = activeSteps[idx - 1]
    }

    // MARK: - HealthKit

    func requestHealthKitAuth() async {
        guard HealthKitService.isAvailable else { return }
        isRequestingHealthKit = true
        defer { isRequestingHealthKit = false }

        do {
            try await healthKitService.requestAuthorization()
            healthKitAuthorized = true
        } catch {
            Loggers.healthKit.error("Onboarding HealthKit auth failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Notifications

    func requestNotificationPermission() async {
        isRequestingNotifications = true
        defer { isRequestingNotifications = false }

        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            notificationsAuthorized = granted
        } catch {
            Loggers.security.error("Notification permission failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Completion

    func completeOnboarding(context: ModelContext) {
        let descriptor = FetchDescriptor<UserPreferences>()
        let prefs: UserPreferences

        if let existing = try? context.fetch(descriptor).first {
            prefs = existing
        } else {
            prefs = UserPreferences()
            context.insert(prefs)
        }

        prefs.hasCompletedOnboarding = true
        prefs.hasRequestedHealthKitAuth = healthKitAuthorized
        prefs.updatedAt = Date()

        // Save selected sync types
        if syncEnabled {
            let selectedRawValues = metrics
                .filter(\.isSelected)
                .flatMap { metric in
                    HealthDataType.groupedByCategory
                        .first { $0.category == metric.category }?
                        .types
                        .map(\.rawValue) ?? []
                }

            let syncDescriptor = FetchDescriptor<SyncConfiguration>()
            let syncConfig: SyncConfiguration

            if let existing = try? context.fetch(syncDescriptor).first {
                syncConfig = existing
            } else {
                syncConfig = SyncConfiguration()
                context.insert(syncConfig)
            }

            syncConfig.isEnabled = true
            syncConfig.enabledTypeRawValues = selectedRawValues
            syncConfig.updatedAt = Date()
        }

        try? context.save()
    }

    // MARK: - Helpers

    func toggleMetric(_ metric: DashboardMetric) {
        guard let idx = metrics.firstIndex(where: { $0.category == metric.category }) else { return }
        metrics[idx].isSelected.toggle()
    }

    private static func defaultMetrics() -> [DashboardMetric] {
        let defaultSelected: Set<HealthDataCategory> = [.activity, .heart, .sleep, .fitness]
        return HealthDataCategory.allCases
            .filter { $0 != .characteristics && $0 != .other }
            .map { DashboardMetric(category: $0, isSelected: defaultSelected.contains($0)) }
    }
}
