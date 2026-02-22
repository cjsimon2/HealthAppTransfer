import SwiftData
import SwiftUI

// MARK: - Automations View

struct AutomationsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query(sort: \AutomationConfiguration.createdAt, order: .reverse)
    private var automations: [AutomationConfiguration]

    // MARK: - State

    @State private var showingTypePicker = false
    @State private var showingRESTForm = false
    @State private var showingMQTTForm = false
    @State private var showingCloudStorageForm = false
    @State private var showingCalendarForm = false
    @State private var showingHomeAssistantForm = false

    // MARK: - Body

    var body: some View {
        Group {
            if automations.isEmpty {
                emptyState
            } else {
                automationList
            }
        }
        .navigationTitle("Automations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingRESTForm = true
                    } label: {
                        Label("REST API", systemImage: "network")
                    }

                    Button {
                        showingMQTTForm = true
                    } label: {
                        Label("MQTT", systemImage: "antenna.radiowaves.left.and.right")
                    }

                    Button {
                        showingCloudStorageForm = true
                    } label: {
                        Label("iCloud Drive", systemImage: "icloud")
                    }

                    Button {
                        showingCalendarForm = true
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }

                    Button {
                        showingHomeAssistantForm = true
                    } label: {
                        Label("Home Assistant", systemImage: "house")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add automation")
                .accessibilityIdentifier("automations.addMenu")
            }
        }
        .sheet(isPresented: $showingRESTForm) {
            NavigationStack {
                RESTAutomationFormView()
            }
        }
        .sheet(isPresented: $showingMQTTForm) {
            NavigationStack {
                MQTTAutomationFormView()
            }
        }
        .sheet(isPresented: $showingCloudStorageForm) {
            NavigationStack {
                CloudStorageFormView()
            }
        }
        .sheet(isPresented: $showingCalendarForm) {
            NavigationStack {
                CalendarFormView()
            }
        }
        .sheet(isPresented: $showingHomeAssistantForm) {
            NavigationStack {
                HomeAssistantFormView()
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "bolt.horizontal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            Text("No Automations")
                .font(.title2.bold())

            Text("Automatically push health data to REST APIs, MQTT brokers, iCloud Drive, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Menu {
                Button {
                    showingRESTForm = true
                } label: {
                    Label("REST API", systemImage: "network")
                }

                Button {
                    showingMQTTForm = true
                } label: {
                    Label("MQTT", systemImage: "antenna.radiowaves.left.and.right")
                }

                Button {
                    showingCloudStorageForm = true
                } label: {
                    Label("iCloud Drive", systemImage: "icloud")
                }

                Button {
                    showingCalendarForm = true
                } label: {
                    Label("Calendar", systemImage: "calendar")
                }

                Button {
                    showingHomeAssistantForm = true
                } label: {
                    Label("Home Assistant", systemImage: "house")
                }
            } label: {
                Label("Add Automation", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
            .accessibilityIdentifier("automations.emptyState.addMenu")

            Spacer()
        }
        .accessibilityIdentifier("automations.emptyState")
    }

    private var automationList: some View {
        List {
            ForEach(automations) { automation in
                NavigationLink {
                    automationDetailView(for: automation)
                } label: {
                    automationRow(automation)
                }
            }
            .onDelete(perform: deleteAutomations)
        }
    }

    @ViewBuilder
    private func automationDetailView(for automation: AutomationConfiguration) -> some View {
        switch automation.automationType {
        case "mqtt":
            MQTTAutomationFormView(configuration: automation)
        case "cloud_storage":
            CloudStorageFormView(configuration: automation)
        case "calendar":
            CalendarFormView(configuration: automation)
        case "home_assistant":
            HomeAssistantFormView(configuration: automation)
        default:
            RESTAutomationFormView(configuration: automation)
        }
    }

    private func automationRow(_ automation: AutomationConfiguration) -> some View {
        HStack(spacing: 12) {
            Image(systemName: automationIcon(automation))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    (automation.isEnabled ? automationColor(automation) : Color.gray).gradient,
                    in: RoundedRectangle(cornerRadius: 7)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(automation.name)
                    .font(.body.weight(.medium))

                HStack(spacing: 4) {
                    Text(automationTypeLabel(automation.automationType))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if automation.consecutiveFailures > 0 {
                        Text("• \(automation.consecutiveFailures) failures")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let lastRun = automation.lastTriggeredAt {
                    Text("Last run: \(lastRun, format: .relative(presentation: .named))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if automation.triggerIntervalSeconds > 0 {
                    Text(intervalLabel(automation.triggerIntervalSeconds))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.quaternary, in: Capsule())
                } else {
                    Text("On change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.quaternary, in: Capsule())
                }

                if !automation.isEnabled {
                    Text("Paused")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(automationRowLabel(automation))
        .accessibilityIdentifier("automations.row.\(automation.name)")
    }

    private func automationRowLabel(_ automation: AutomationConfiguration) -> String {
        let status = automation.isEnabled ? "enabled" : "disabled"
        let type = automationTypeLabel(automation.automationType)
        var label = "\(automation.name), \(type), \(status)"
        if automation.consecutiveFailures > 0 {
            label += ", \(automation.consecutiveFailures) consecutive failures"
        }
        if automation.lastTriggeredAt != nil {
            label += ", last run recently"
        }
        return label
    }

    private func intervalLabel(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        return "\(seconds / 3600)h"
    }

    // MARK: - Helpers

    private func automationIcon(_ automation: AutomationConfiguration) -> String {
        switch automation.automationType {
        case "mqtt": return "antenna.radiowaves.left.and.right"
        case "cloud_storage": return "icloud"
        case "calendar": return "calendar"
        case "home_assistant": return "house"
        default: return "bolt.fill"
        }
    }

    private func automationColor(_ automation: AutomationConfiguration) -> Color {
        switch automation.automationType {
        case "mqtt": return .purple
        case "cloud_storage": return .blue
        case "calendar": return .red
        case "home_assistant": return .cyan
        default: return .orange
        }
    }

    private func automationTypeLabel(_ type: String) -> String {
        switch type {
        case "rest_api": return "REST API"
        case "mqtt": return "MQTT"
        case "home_assistant": return "Home Assistant"
        case "cloud_storage": return "iCloud Drive"
        case "calendar": return "Calendar"
        default: return type
        }
    }

    private func deleteAutomations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(automations[index])
        }
        try? modelContext.save()
        NotificationCenter.default.post(name: .automationsDidChange, object: nil)
    }
}

// MARK: - Notification Name

extension Notification.Name {
    /// Posted when automations are added, removed, or toggled.
    static let automationsDidChange = Notification.Name("automationsDidChange")
}
