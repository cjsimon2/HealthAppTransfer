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
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Automations")
                .font(.title3.bold())

            Text("Set up automations to automatically push health data to external services.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

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
            } label: {
                Label("Add Automation", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            .accessibilityIdentifier("automations.emptyState.addMenu")
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
        default:
            RESTAutomationFormView(configuration: automation)
        }
    }

    private func automationRow(_ automation: AutomationConfiguration) -> some View {
        HStack(spacing: 12) {
            Image(systemName: automationIcon(automation))
                .foregroundStyle(automation.isEnabled ? .green : .secondary)
                .frame(width: 24)

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
            }

            Spacer()
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
        return label
    }

    // MARK: - Helpers

    private func automationIcon(_ automation: AutomationConfiguration) -> String {
        guard automation.isEnabled else { return "bolt.slash" }
        switch automation.automationType {
        case "mqtt": return "antenna.radiowaves.left.and.right"
        case "cloud_storage": return "icloud"
        case "calendar": return "calendar"
        default: return "bolt.fill"
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
    }
}
