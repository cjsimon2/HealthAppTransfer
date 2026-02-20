import SwiftUI

// MARK: - Welcome Step View

/// First onboarding screen showing app capabilities.
struct WelcomeStepView: View {

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                headerSection

                featuresSection

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Welcome to HealthAppTransfer")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Securely view, export, and transfer your Apple Health data between devices.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            featureRow(
                icon: "list.bullet.clipboard.fill",
                title: "Browse All Health Data",
                description: "Access 180+ health data types organized by category."
            )

            featureRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Device-to-Device Transfer",
                description: "Securely sync health data between your iPhone and Mac over your local network."
            )

            featureRow(
                icon: "lock.shield.fill",
                title: "Private & Secure",
                description: "End-to-end encryption with biometric authentication. Your data never leaves your devices."
            )

            featureRow(
                icon: "bolt.horizontal.fill",
                title: "Automated Sync",
                description: "Set up background sync to keep your devices in sync automatically."
            )
        }
        .padding(20)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
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
}
