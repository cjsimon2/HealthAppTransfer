import SwiftUI
import SwiftData

// MARK: - Goal Settings View

/// Allows users to customize daily goals and streak thresholds for Insights.
struct GoalSettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var preferences: UserPreferences?

    // Goal values
    @State private var stepGoal: Double = 10_000
    @State private var energyGoal: Double = 500
    @State private var distanceGoal: Double = 5_000
    @State private var exerciseGoal: Double = 30

    // Streak threshold values
    @State private var stepStreak: Double = 10_000
    @State private var energyStreak: Double = 500
    @State private var distanceStreak: Double = 5_000
    @State private var exerciseStreak: Double = 30

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                dailyGoalsSection
                streakThresholdsSection
            }
            .navigationTitle("Goal Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear { loadPreferences() }
        }
    }

    // MARK: - Sections

    private var dailyGoalsSection: some View {
        Section {
            goalRow(label: "Steps", value: $stepGoal, range: 1_000...50_000, step: 1_000, unit: "steps")
            goalRow(label: "Active Energy", value: $energyGoal, range: 100...2_000, step: 50, unit: "kcal")
            goalRow(label: "Distance", value: $distanceGoal, range: 1_000...30_000, step: 500, unit: "m")
            goalRow(label: "Exercise Time", value: $exerciseGoal, range: 10...120, step: 5, unit: "min")
        } header: {
            Text("Daily Goals")
        } footer: {
            Text("Set targets for your daily health metrics. These are used to calculate goal progress in Insights.")
        }
    }

    private var streakThresholdsSection: some View {
        Section {
            goalRow(label: "Steps", value: $stepStreak, range: 1_000...50_000, step: 1_000, unit: "steps")
            goalRow(label: "Active Energy", value: $energyStreak, range: 100...2_000, step: 50, unit: "kcal")
            goalRow(label: "Distance", value: $distanceStreak, range: 1_000...30_000, step: 500, unit: "m")
            goalRow(label: "Exercise Time", value: $exerciseStreak, range: 10...120, step: 5, unit: "min")
        } header: {
            Text("Streak Thresholds")
        } footer: {
            Text("Minimum daily amount to count toward a streak.")
        }
    }

    // MARK: - Row

    private func goalRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue).formatted()) \(unit)")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .accessibilityValue("\(Int(value.wrappedValue)) \(unit)")
    }

    // MARK: - Persistence

    private func loadPreferences() {
        let descriptor = FetchDescriptor<UserPreferences>()
        guard let prefs = try? modelContext.fetch(descriptor).first else { return }
        preferences = prefs

        // Load custom values, falling back to defaults
        stepGoal = prefs.customGoals[HealthDataType.stepCount.rawValue] ?? 10_000
        energyGoal = prefs.customGoals[HealthDataType.activeEnergyBurned.rawValue] ?? 500
        distanceGoal = prefs.customGoals[HealthDataType.distanceWalkingRunning.rawValue] ?? 5_000
        exerciseGoal = prefs.customGoals[HealthDataType.appleExerciseTime.rawValue] ?? 30

        stepStreak = prefs.customStreakThresholds[HealthDataType.stepCount.rawValue] ?? 10_000
        energyStreak = prefs.customStreakThresholds[HealthDataType.activeEnergyBurned.rawValue] ?? 500
        distanceStreak = prefs.customStreakThresholds[HealthDataType.distanceWalkingRunning.rawValue] ?? 5_000
        exerciseStreak = prefs.customStreakThresholds[HealthDataType.appleExerciseTime.rawValue] ?? 30
    }

    private func save() {
        let descriptor = FetchDescriptor<UserPreferences>()
        guard let prefs = try? modelContext.fetch(descriptor).first else { return }

        prefs.customGoals = [
            HealthDataType.stepCount.rawValue: stepGoal,
            HealthDataType.activeEnergyBurned.rawValue: energyGoal,
            HealthDataType.distanceWalkingRunning.rawValue: distanceGoal,
            HealthDataType.appleExerciseTime.rawValue: exerciseGoal,
        ]

        prefs.customStreakThresholds = [
            HealthDataType.stepCount.rawValue: stepStreak,
            HealthDataType.activeEnergyBurned.rawValue: energyStreak,
            HealthDataType.distanceWalkingRunning.rawValue: distanceStreak,
            HealthDataType.appleExerciseTime.rawValue: exerciseStreak,
        ]

        prefs.updatedAt = Date()
    }
}
