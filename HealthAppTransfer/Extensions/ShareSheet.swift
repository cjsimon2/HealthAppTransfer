import SwiftUI
import UniformTypeIdentifiers

// MARK: - Share Sheet View

/// Cross-platform share sheet: UIActivityViewController on iOS, NSSharingServicePicker on macOS.
struct ShareSheetView: View {
    let fileURL: URL
    var onDismiss: (() -> Void)?

    var body: some View {
        #if os(iOS)
        ShareSheetRepresentable(fileURL: fileURL, onDismiss: onDismiss)
            .ignoresSafeArea()
        #else
        MacShareView(fileURL: fileURL, onDismiss: onDismiss)
        #endif
    }
}

// MARK: - iOS Share Sheet

#if os(iOS)
import UIKit

private struct ShareSheetRepresentable: UIViewControllerRepresentable {
    let fileURL: URL
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - macOS Share View

#if os(macOS)
import AppKit

private struct MacShareView: View {
    let fileURL: URL
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text("Export Complete")
                .font(.title2.weight(.semibold))

            Text(fileURL.lastPathComponent)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ShareButton(fileURL: fileURL)

                Button("Save to Disk...") {
                    showSavePanel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(32)
    }

    private func showSavePanel() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileURL.lastPathComponent
        panel.allowedContentTypes = [ShareFileHelper.contentType(for: fileURL.pathExtension)]
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let saveURL = panel.url {
            try? FileManager.default.copyItem(at: fileURL, to: saveURL)
        }
        onDismiss?()
    }
}

/// Wraps NSSharingServicePicker for use in SwiftUI.
private struct ShareButton: NSViewRepresentable {
    let fileURL: URL

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "Share…", target: context.coordinator, action: #selector(Coordinator.showPicker(_:)))
        button.bezelStyle = .rounded
        button.controlSize = .large
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.fileURL = fileURL
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(fileURL: fileURL)
    }

    class Coordinator: NSObject {
        var fileURL: URL

        init(fileURL: URL) {
            self.fileURL = fileURL
        }

        @objc func showPicker(_ sender: NSButton) {
            let picker = NSSharingServicePicker(items: [fileURL])
            picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
}
#endif

// MARK: - Share File Helper

enum ShareFileHelper {

    /// Returns the UTType for a file extension.
    static func contentType(for fileExtension: String) -> UTType {
        switch fileExtension {
        case "json": return .json
        case "csv": return .commaSeparatedText
        case "gpx": return UTType(filenameExtension: "gpx") ?? .xml
        default: return .data
        }
    }

    /// Creates a temporary file for sharing and returns its URL.
    static func createTempFile(data: Data, fileName: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("share", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    /// Cleans up temporary share files.
    static func cleanupTempFiles() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
    }
}
