import SwiftUI
import SwiftData

// MARK: - Security Settings View

struct SecuritySettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Observed Objects

    @ObservedObject var viewModel: SecuritySettingsViewModel

    // MARK: - State

    @State private var pendingToggle = false

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Toggle(isOn: biometricBinding) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Require \(viewModel.biometricName)")
                            Text("Authenticate on app launch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: viewModel.biometricIconName)
                    }
                }
                .disabled(!viewModel.canUseBiometrics || viewModel.isAuthenticating)
                .accessibilityLabel("Require \(viewModel.biometricName) to unlock the app")
                .accessibilityHint(viewModel.canUseBiometrics ? "Double-tap to toggle" : "Biometric authentication is not available")
                .accessibilityIdentifier("security.biometricToggle")
            } header: {
                Text("App Lock")
            } footer: {
                if !viewModel.canUseBiometrics {
                    Text("Biometric authentication is not available on this device.")
                } else {
                    Text("When enabled, \(viewModel.biometricName) or your device passcode is required to open the app and access sensitive operations like data export.")
                }
            }

            if viewModel.isBiometricEnabled {
                Section {
                    Label {
                        Text("Export requires re-authentication")
                    } icon: {
                        Image(systemName: "square.and.arrow.up.on.square")
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("security.exportProtection")

                    Label {
                        Text("API access returns locked when unauthenticated")
                    } icon: {
                        Image(systemName: "network.badge.shield.half.filled")
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("security.apiProtection")
                } header: {
                    Text("Protected Operations")
                }
            }

            if let error = viewModel.error {
                Section {
                    Label {
                        Text(error)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Security")
        .onAppear {
            viewModel.loadPreference(from: modelContext)
        }
    }

    // MARK: - Helpers

    private var biometricBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isBiometricEnabled },
            set: { newValue in
                Task {
                    await viewModel.toggleBiometric(enabled: newValue, context: modelContext)
                }
            }
        )
    }
}
