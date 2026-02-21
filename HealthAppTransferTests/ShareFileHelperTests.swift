import XCTest
import UniformTypeIdentifiers
@testable import HealthAppTransfer

final class ShareFileHelperTests: XCTestCase {

    // MARK: - contentType

    func testContentTypeForJSON() {
        XCTAssertEqual(ShareFileHelper.contentType(for: "json"), .json)
    }

    func testContentTypeForCSV() {
        XCTAssertEqual(ShareFileHelper.contentType(for: "csv"), .commaSeparatedText)
    }

    func testContentTypeForGPX() {
        let result = ShareFileHelper.contentType(for: "gpx")
        // Should be either a gpx UTType or fall back to .xml
        let expected = UTType(filenameExtension: "gpx") ?? .xml
        XCTAssertEqual(result, expected)
    }

    func testContentTypeForUnknownReturnsData() {
        XCTAssertEqual(ShareFileHelper.contentType(for: "xyz"), .data)
    }

    // MARK: - createTempFile

    func testCreateTempFileWritesAndReturnsValidURL() throws {
        let testData = Data("test content".utf8)
        let url = try ShareFileHelper.createTempFile(data: testData, fileName: "test.json")

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let readBack = try Data(contentsOf: url)
        XCTAssertEqual(readBack, testData)

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - cleanupTempFiles

    func testCleanupTempFilesRemovesDirectory() throws {
        // Create a temp file first
        let testData = Data("cleanup test".utf8)
        let url = try ShareFileHelper.createTempFile(data: testData, fileName: "cleanup.json")
        let dir = url.deletingLastPathComponent()
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path))

        ShareFileHelper.cleanupTempFiles()

        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.path))
    }
}
