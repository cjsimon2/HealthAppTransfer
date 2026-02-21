import XCTest
@testable import HealthAppTransfer

final class QRCodeRendererTests: XCTestCase {

    // MARK: - CGImage Generation

    func testGenerateWithValidStringReturnsNonNilCGImage() {
        let image = QRCodeRenderer.generate(from: "https://example.com")
        XCTAssertNotNil(image)
    }

    func testGenerateWithEmptyStringReturnsImage() {
        // QR codes can encode empty strings
        let image = QRCodeRenderer.generate(from: "")
        XCTAssertNotNil(image)
    }

    func testGenerateWithLongStringReturnsImage() {
        let longString = String(repeating: "A", count: 500)
        let image = QRCodeRenderer.generate(from: longString)
        XCTAssertNotNil(image)
    }

    // MARK: - SwiftUI Image Generation

    func testImageFromValidStringReturnsNonNilImage() {
        let image = QRCodeRenderer.image(from: "test-payload")
        XCTAssertNotNil(image)
    }

    // MARK: - Size Parameter

    func testGenerateRespectsCustomSize() {
        let size: CGFloat = 400
        let image = QRCodeRenderer.generate(from: "test", size: size)
        XCTAssertNotNil(image)
        // The generated image should have dimensions approximately matching the requested size
        if let image {
            XCTAssertEqual(CGFloat(image.width), size, accuracy: 1.0)
            XCTAssertEqual(CGFloat(image.height), size, accuracy: 1.0)
        }
    }

    func testImageFromWithCustomSize() {
        let image = QRCodeRenderer.image(from: "test", size: 300)
        XCTAssertNotNil(image)
    }

    func testDefaultSizeIsUsed() {
        let image = QRCodeRenderer.generate(from: "test")
        XCTAssertNotNil(image)
        if let image {
            // Default size is 200
            XCTAssertEqual(CGFloat(image.width), 200, accuracy: 1.0)
            XCTAssertEqual(CGFloat(image.height), 200, accuracy: 1.0)
        }
    }
}
