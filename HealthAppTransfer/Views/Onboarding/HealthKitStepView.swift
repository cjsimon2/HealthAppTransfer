import SwiftUI

// MARK: - HealthKit Step View

/// Onboarding step explaining HealthKit data access and triggering authorization.
struct HealthKitStepView: View {

    // MARK: - Properties

    let isAuthorized: Bool
    let isRequesting: Bool
    let onAuthorize: () async -> Void

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                headerSection

                dataTypesSection

                authorizeButton

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text("Health Data Access")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("HealthAppTransfer needs read access to your health data so you can browse, export, and transfer it.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var dataTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("We'll request access to:")
                .font(.subheadline.weight(.medium))

            dataTypeRow(icon: "flame.fill", text: "Activity & Fitness")
            dataTypeRow(icon: "heart.fill", text: "Heart & Vitals")
            dataTypeRow(icon: "bed.double.fill", text: "Sleep & Mindfulness")
            dataTypeRow(icon: "fork.knife", text: "Nutrition & Body Measurements")
            dataTypeRow(icon: "figure.walk", text: "Mobility & Workouts")

            Text("Read-only access. We never write to your Health data.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(20)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func dataTypeRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    private var authorizeButton: some View {
        Group {
            if isAuthorized {
                Label("Access Granted", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else if !HealthKitService.isAvailable {
                Text("HealthKit is not available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    Task { await onAuthorize() }
                } label: {
                    if isRequesting {
                        ProgressView()
                            .frame(maxWidth: 280)
                    } else {
                        Text("Authorize Health Access")
                            .fontWeight(.semibold)
                            .frame(maxWidth: 280)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequesting)
            }
        }
        .accessibilityLabel(isAuthorized ? "Health data access granted" : "Authorize health data access")
    }
}
