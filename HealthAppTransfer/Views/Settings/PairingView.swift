import SwiftData
import SwiftUI

// MARK: - Pairing View

/// Platform-conditional pairing view.
/// iOS: Displays QR code for macOS client to scan.
/// macOS: Provides scan/paste interface to pair with iOS server.
struct PairingView: View {
    @ObservedObject var viewModel: PairingViewModel

    var body: some View {
        #if os(iOS)
        iOSPairingView(viewModel: viewModel)
        #else
        macOSPairingView(viewModel: viewModel)
        #endif
    }
}

// MARK: - iOS Pairing View (QR Display)

#if os(iOS)
private struct iOSPairingView: View {
    @ObservedObject var viewModel: PairingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                if viewModel.isServerRunning {
                    qrCodeSection
                    pairingCodeSection
                    countdownSection
                    controlsSection
                } else {
                    startSection
                }

                if let error = viewModel.error {
                    errorBanner(error)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("Pair Device")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "qrcode")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Device Pairing")
                .font(.title2.bold())

            Text("Scan this QR code with the companion Mac app to pair devices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var qrCodeSection: some View {
        Group {
            if let qrImage = viewModel.qrImage {
                qrImage
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            } else {
                ProgressView("Generating QR code…")
                    .frame(width: 240, height: 240)
            }
        }
    }

    private var pairingCodeSection: some View {
        VStack(spacing: 4) {
            Text("Pairing Code")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(viewModel.pairingCode)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .tracking(4)
                .accessibilityLabel("Pairing code: \(viewModel.pairingCode.map(String.init).joined(separator: " "))")
        }
    }

    private var countdownSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .foregroundStyle(countdownColor)

            Text(countdownText)
                .font(.subheadline)
                .foregroundStyle(countdownColor)
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await viewModel.refreshCode() }
            } label: {
                Label("New Code", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                Task { await viewModel.stopSharing() }
            } label: {
                Label("Stop Sharing", systemImage: "stop.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 8)
    }

    private var startSection: some View {
        VStack(spacing: 16) {
            if viewModel.isPreparing {
                ProgressView("Starting server…")
            } else {
                Button {
                    Task { await viewModel.startSharing() }
                } label: {
                    Label("Start Sharing", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 24)
    }

    // MARK: - Helpers

    private var countdownColor: Color {
        viewModel.timeRemaining < 60 ? .red : .secondary
    }

    private var countdownText: String {
        let minutes = viewModel.timeRemaining / 60
        let seconds = viewModel.timeRemaining % 60
        return "Expires in \(minutes):\(String(format: "%02d", seconds))"
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
        }
        .padding(12)
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
#endif

// MARK: - macOS Pairing View (QR Scan / Paste)

#if os(macOS)
private struct macOSPairingView: View {
    @ObservedObject var viewModel: PairingViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var clipboardInput: String = ""
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                pasteSection

                if let payload = viewModel.scannedPayload {
                    payloadPreview(payload)
                    pairButton
                }

                if viewModel.pairingSuccess {
                    successBanner
                }

                if let error = viewModel.scanError {
                    errorBanner(error)
                }
            }
            .padding(24)
        }
        .navigationTitle("Pair with iPhone")
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Connect to iPhone")
                .font(.title2.bold())

            Text("Paste the QR code data from your iPhone to pair.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var pasteSection: some View {
        VStack(spacing: 12) {
            TextEditor(text: $clipboardInput)
                .font(.system(.body, design: .monospaced))
                .frame(height: 100)
                .border(Color.secondary.opacity(0.3))

            HStack(spacing: 12) {
                Button("Paste from Clipboard") {
                    if let string = NSPasteboard.general.string(forType: .string) {
                        clipboardInput = string
                        viewModel.parseClipboard(string)
                    }
                }
                .buttonStyle(.bordered)

                Button("Parse") {
                    viewModel.parseClipboard(clipboardInput)
                }
                .buttonStyle(.borderedProminent)
                .disabled(clipboardInput.isEmpty)
            }
        }
    }

    private func payloadPreview(_ payload: QRPairingPayload) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Server Found", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("Host:").foregroundStyle(.secondary)
                    Text(payload.host).font(.system(.body, design: .monospaced))
                }
                GridRow {
                    Text("Port:").foregroundStyle(.secondary)
                    Text("\(payload.port)").font(.system(.body, design: .monospaced))
                }
                GridRow {
                    Text("Code:").foregroundStyle(.secondary)
                    Text(payload.code).font(.system(.body, design: .monospaced))
                }
                GridRow {
                    Text("Expires:").foregroundStyle(.secondary)
                    Text(payload.expiryDate, style: .relative)
                }
            }
        }
        .padding(16)
        .background(.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var pairButton: some View {
        Button {
            Task { await viewModel.completePairing(modelContext: modelContext) }
        } label: {
            if viewModel.isPairing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label("Pair Now", systemImage: "link.badge.plus")
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isPairing)
    }

    private var successBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Successfully paired! You can now transfer health data.")
                .font(.subheadline)
        }
        .padding(12)
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
        }
        .padding(12)
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
#endif
