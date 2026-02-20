import SwiftData
import SwiftUI

// MARK: - Automations View

struct AutomationsView: View {

    // MARK: - Queries

    @Query(sort: \AutomationConfiguration.createdAt, order: .reverse)
    private var automations: [AutomationConfiguration]

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
        }
    }

    private var automationList: some View {
        List {
            ForEach(automations) { automation in
                HStack(spacing: 12) {
                    Image(systemName: automation.isEnabled ? "bolt.fill" : "bolt.slash")
                        .foregroundStyle(automation.isEnabled ? .green : .secondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(automation.name)
                            .font(.body.weight(.medium))

                        Text(automation.automationType)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
}
