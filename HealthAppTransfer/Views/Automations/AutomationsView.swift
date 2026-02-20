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

    @State private var showingAddSheet = false

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
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                RESTAutomationFormView()
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Automations")
                .font(.title3.bold())

            Text("Set up automations to automatically push health data to external services.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Automation", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }

    private var automationList: some View {
        List {
            ForEach(automations) { automation in
                NavigationLink {
                    RESTAutomationFormView(configuration: automation)
                } label: {
                    automationRow(automation)
                }
            }
            .onDelete(perform: deleteAutomations)
        }
    }

    private func automationRow(_ automation: AutomationConfiguration) -> some View {
        HStack(spacing: 12) {
            Image(systemName: automation.isEnabled ? "bolt.fill" : "bolt.slash")
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
    }

    // MARK: - Helpers

    private func automationTypeLabel(_ type: String) -> String {
        switch type {
        case "rest_api": return "REST API"
        case "mqtt": return "MQTT"
        case "home_assistant": return "Home Assistant"
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
