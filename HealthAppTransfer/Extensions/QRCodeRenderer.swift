import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

// MARK: - QR Code Renderer

enum QRCodeRenderer {

    /// Generate a QR code `CGImage` from a string payload.
    /// Returns nil if generation fails.
    static func generate(from string: String, size: CGFloat = 200) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return nil }

        let scaleX = size / ciImage.extent.width
        let scaleY = size / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        return context.createCGImage(scaled, from: scaled.extent)
    }

    /// Generate a SwiftUI `Image` from a string payload.
    static func image(from string: String, size: CGFloat = 200) -> Image? {
        guard let cgImage = generate(from: string, size: size) else { return nil }
        return Image(decorative: cgImage, scale: 1.0)
    }
}
