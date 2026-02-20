import SwiftUI

// MARK: - Notification Step View

/// Onboarding step requesting push notification permission.
/// Skipped on macOS.
struct NotificationStepView: View {

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

                benefitsSection

                authorizeButton

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text("Stay Informed")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Get notified when transfers complete, sync runs in the background, or a new device pairs.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Sync Completed",
                description: "Know when background sync finishes transferring data."
            )

            benefitRow(
                icon: "macbook.and.iphone",
                title: "New Device Paired",
                description: "Get alerted when another device connects to your account."
            )

            benefitRow(
                icon: "exclamationmark.triangle",
                title: "Transfer Issues",
                description: "Be notified if a sync or export encounters an error."
            )
        }
        .padding(20)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var authorizeButton: some View {
        Group {
            if isAuthorized {
                Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else {
                Button {
                    Task { await onAuthorize() }
                } label: {
                    if isRequesting {
                        ProgressView()
                            .frame(maxWidth: 280)
                    } else {
                        Text("Enable Notifications")
                            .fontWeight(.semibold)
                            .frame(maxWidth: 280)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
                .disabled(isRequesting)
            }
        }
        .accessibilityLabel(isAuthorized ? "Notifications enabled" : "Enable notifications")
    }
}
