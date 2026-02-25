import SwiftUI
import SwiftData

// MARK: - Notification Settings View

/// Settings screen for configuring Insights notifications.
struct NotificationSettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var notificationsEnabled = true
    @State private var streakAlertsEnabled = true
    @State private var goalAlertsEnabled = true
    @State private var authorizationDenied = false

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            requestAuthorization()
                        }
                        savePreference(\.notificationsEnabled, value: newValue)
                    }
                    .accessibilityIdentifier("notifications.masterToggle")
            } footer: {
                if authorizationDenied {
                    Text("Notifications are disabled in System Settings. Open Settings to enable them.")
                        .foregroundStyle(.red)
                }
            }

            if notificationsEnabled {
                Section {
                    Toggle("Streak at Risk", isOn: $streakAlertsEnabled)
                        .onChange(of: streakAlertsEnabled) { _, newValue in
                            savePreference(\.streakAlertsEnabled, value: newValue)
                        }
                        .accessibilityIdentifier("notifications.streakAlerts")

                    Toggle("Goal Nearly Met", isOn: $goalAlertsEnabled)
                        .onChange(of: goalAlertsEnabled) { _, newValue in
                            savePreference(\.goalAlertsEnabled, value: newValue)
                        }
                        .accessibilityIdentifier("notifications.goalAlerts")
                } header: {
                    Text("Alert Types")
                } footer: {
                    Text("Streak alerts fire when your streak is at risk of breaking. Goal alerts fire when you're 90% or more to your daily goal.")
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear { loadPreferences() }
    }

    // MARK: - Persistence

    private func loadPreferences() {
        let descriptor = FetchDescriptor<UserPreferences>()
        guard let prefs = try? modelContext.fetch(descriptor).first else { return }
        notificationsEnabled = prefs.notificationsEnabled
        streakAlertsEnabled = prefs.streakAlertsEnabled
        goalAlertsEnabled = prefs.goalAlertsEnabled
    }

    private func savePreference(_ keyPath: ReferenceWritableKeyPath<UserPreferences, Bool>, value: Bool) {
        let descriptor = FetchDescriptor<UserPreferences>()
        guard let prefs = try? modelContext.fetch(descriptor).first else { return }
        prefs[keyPath: keyPath] = value
        prefs.updatedAt = Date()
    }

    private func requestAuthorization() {
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            if !granted {
                authorizationDenied = true
                notificationsEnabled = false
                savePreference(\.notificationsEnabled, value: false)
            }
        }
    }
}
