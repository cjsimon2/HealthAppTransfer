import EventKit
import SwiftData
import SwiftUI

// MARK: - Calendar Form View

/// Form for creating or editing a Calendar automation that creates workout events.
struct CalendarFormView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var name: String
    @State private var incrementalOnly: Bool
    @State private var calendarAccessGranted: Bool?

    /// Existing configuration to edit, or nil when creating new.
    private let existing: AutomationConfiguration?

    // MARK: - Init

    init(configuration: AutomationConfiguration? = nil) {
        self.existing = configuration
        _name = State(initialValue: configuration?.name ?? "")
        _incrementalOnly = State(initialValue: configuration?.incrementalOnly ?? true)
    }

    // MARK: - Body

    var body: some View {
        Form {
            generalSection
            calendarInfoSection
            permissionSection
        }
        .navigationTitle(existing == nil ? "New Calendar Automation" : "Edit Calendar Automation")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
                    .accessibilityIdentifier("calendarForm.saveButton")
            }
            if existing == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await checkCalendarAccess()
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        Section("General") {
            TextField("Name", text: $name)
                .accessibilityLabel("Automation name")
                .accessibilityIdentifier("calendarForm.nameField")

            Toggle("Only add new workouts", isOn: $incrementalOnly)
                .accessibilityLabel("Only add new workouts since last run")
                .accessibilityIdentifier("calendarForm.incrementalToggle")
        }
    }

    private var calendarInfoSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Events")
                        .font(.body.weight(.medium))

                    Text("Creates calendar events for each workout with activity type, duration, calories, and distance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "figure.run")
                    .foregroundStyle(AppColors.accent)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("calendarForm.infoSection")
        } header: {
            Text("What This Does")
        }
    }

    private var permissionSection: some View {
        Section {
            HStack(spacing: 12) {
                Group {
                    if let granted = calendarAccessGranted {
                        Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(granted ? .green : .red)
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    if let granted = calendarAccessGranted {
                        Text(granted ? "Calendar Access Granted" : "Calendar Access Denied")
                            .font(.body.weight(.medium))

                        if !granted {
                            Text("Enable in Settings > Privacy > Calendars.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Checking calendar access...")
                            .font(.body.weight(.medium))
                    }
                }
            }

            if calendarAccessGranted == nil || calendarAccessGranted == false {
                Button("Request Calendar Access") {
                    Task { await requestAccess() }
                }
                .accessibilityIdentifier("calendarForm.requestAccessButton")
            }
        } header: {
            Text("Permissions")
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Calendar Access

    private func checkCalendarAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .authorized:
            calendarAccessGranted = true
        case .denied, .restricted:
            calendarAccessGranted = false
        case .notDetermined, .writeOnly:
            calendarAccessGranted = nil
        @unknown default:
            calendarAccessGranted = nil
        }
    }

    private func requestAccess() async {
        let store = EKEventStore()
        do {
            let granted: Bool
            if #available(iOS 17.0, macOS 14.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            calendarAccessGranted = granted
        } catch {
            calendarAccessGranted = false
        }
    }

    // MARK: - Actions

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let config = existing {
            config.name = trimmedName
            config.incrementalOnly = incrementalOnly
            // Calendar automation always targets workouts
            config.enabledTypeRawValues = [HealthDataType.workout.rawValue]
            config.updatedAt = Date()
        } else {
            let config = AutomationConfiguration(
                name: trimmedName,
                automationType: "calendar"
            )
            config.incrementalOnly = incrementalOnly
            // Calendar automation always targets workouts
            config.enabledTypeRawValues = [HealthDataType.workout.rawValue]
            modelContext.insert(config)
        }

        try? modelContext.save()
        NotificationCenter.default.post(name: .automationsDidChange, object: nil)
        dismiss()
    }
}
