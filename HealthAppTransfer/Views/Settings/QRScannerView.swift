import SwiftUI

#if os(macOS)
import AVFoundation
import Vision

// MARK: - QR Scanner View (macOS)

/// Camera-based QR code scanner for macOS using AVFoundation and Vision.
struct QRScannerView: NSViewRepresentable {
    let onCodeDetected: (String) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = CameraPreviewView()
        view.setAccessibilityLabel("QR code scanner camera view")
        view.setAccessibilityRole(.image)
        context.coordinator.setupCapture(in: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeDetected: onCodeDetected)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let onCodeDetected: (String) -> Void
        private var captureSession: AVCaptureSession?
        private var lastDetectedCode: String?

        init(onCodeDetected: @escaping (String) -> Void) {
            self.onCodeDetected = onCodeDetected
        }

        func setupCapture(in view: CameraPreviewView) {
            let session = AVCaptureSession()
            session.sessionPreset = .medium

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                Loggers.pairing.warning("No camera available for QR scanning")
                return
            }

            guard session.canAddInput(input) else { return }
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "qr-scanner"))

            guard session.canAddOutput(output) else { return }
            session.addOutput(output)

            view.previewLayer.session = session
            captureSession = session

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }

        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let request = VNDetectBarcodesRequest { [weak self] request, _ in
                guard let results = request.results as? [VNBarcodeObservation] else { return }

                for barcode in results {
                    guard barcode.symbology == .qr,
                          let payload = barcode.payloadStringValue,
                          payload != self?.lastDetectedCode else { continue }

                    self?.lastDetectedCode = payload
                    DispatchQueue.main.async { [weak self] in
                        self?.onCodeDetected(payload)
                    }
                }
            }

            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer).perform([request])
        }

        func stopCapture() {
            captureSession?.stopRunning()
            captureSession = nil
        }

        deinit {
            captureSession?.stopRunning()
        }
    }
}

// MARK: - Camera Preview NSView

class CameraPreviewView: NSView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        wantsLayer = true
        previewLayer.videoGravity = .resizeAspectFill
        layer?.addSublayer(previewLayer)
    }

    override func layout() {
        super.layout()
        previewLayer.frame = bounds
    }
}

#elseif os(iOS)
import AVFoundation

// MARK: - QR Scanner View (iOS)

/// Camera-based QR code scanner for iOS using AVCaptureMetadataOutput.
struct QRScannerView: UIViewControllerRepresentable {
    let onCodeDetected: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeDetected = onCodeDetected
        controller.view.accessibilityLabel = "QR code scanner camera view"
        controller.view.isAccessibilityElement = true
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeDetected: ((String) -> Void)?
    private var captureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()

        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let string = object.stringValue else { return }

        captureSession?.stopRunning()
        onCodeDetected?(string)
    }
}
#endif
