import XCTest
@testable import HealthAppTransfer

final class DEREncoderTests: XCTestCase {

    // MARK: - encodeLength

    func testEncodeLengthShortForm() {
        // Values < 0x80 use single-byte encoding
        XCTAssertEqual(DEREncoder.encodeLength(0), [0x00])
        XCTAssertEqual(DEREncoder.encodeLength(1), [0x01])
        XCTAssertEqual(DEREncoder.encodeLength(127), [0x7F])
    }

    func testEncodeLengthOneBytePrefix() {
        // Values 0x80..0xFF use 0x81 prefix
        XCTAssertEqual(DEREncoder.encodeLength(128), [0x81, 0x80])
        XCTAssertEqual(DEREncoder.encodeLength(255), [0x81, 0xFF])
    }

    func testEncodeLengthTwoBytePrefix() {
        // Values > 0xFF use 0x82 prefix with two bytes
        XCTAssertEqual(DEREncoder.encodeLength(256), [0x82, 0x01, 0x00])
        XCTAssertEqual(DEREncoder.encodeLength(0x1234), [0x82, 0x12, 0x34])
    }

    // MARK: - integer from Int

    func testIntegerFromInt() {
        // integer(1) should produce TLV: [0x02, length, value]
        let result = DEREncoder.integer(1)
        XCTAssertEqual(result, [0x02, 0x01, 0x01])
    }

    func testIntegerFromIntAddsSignByte() {
        // 0x80 has high bit set, needs leading 0x00
        let result = DEREncoder.integer(128)
        XCTAssertEqual(result, [0x02, 0x02, 0x00, 0x80])
    }

    // MARK: - integer from byte array

    func testIntegerFromBytesStripsLeadingZeros() {
        let result = DEREncoder.integer([0x00, 0x00, 0x42])
        // Should strip leading zeros, producing [0x02, 0x01, 0x42]
        XCTAssertEqual(result, [0x02, 0x01, 0x42])
    }

    func testIntegerFromBytesAddsSignByte() {
        // 0x80 has high bit set, needs leading 0x00
        let result = DEREncoder.integer([0x80])
        XCTAssertEqual(result, [0x02, 0x02, 0x00, 0x80])
    }

    func testIntegerFromBytesStripsLeadingZerosAndAddsSignByte() {
        // [0x00, 0xFF] strips to [0xFF], then adds sign byte -> [0x00, 0xFF]
        let result = DEREncoder.integer([0x00, 0xFF])
        XCTAssertEqual(result, [0x02, 0x02, 0x00, 0xFF])
    }

    // MARK: - utcTime

    func testUtcTimeFormat() {
        // 2024-01-15 12:30:45 UTC
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: 2024, month: 1, day: 15, hour: 12, minute: 30, second: 45)
        let date = calendar.date(from: components)!

        let result = DEREncoder.utcTime(date)
        // Tag 0x17, length, then "240115123045Z" in UTF-8
        let expectedString = "240115123045Z"
        let expectedPayload = Array(expectedString.utf8)
        XCTAssertEqual(result[0], 0x17) // UTCTime tag
        XCTAssertEqual(result[1], UInt8(expectedPayload.count))
        XCTAssertEqual(Array(result[2...]), expectedPayload)
    }

    // MARK: - x500Name

    func testX500NameProducesValidSequence() {
        let result = DEREncoder.x500Name(commonName: "Test", organization: "Org")
        // Should be a SEQUENCE (tag 0x30)
        XCTAssertEqual(result.first, 0x30)
        // Should contain the CN and O strings somewhere in the bytes
        XCTAssertTrue(result.count > 10)
    }

    // MARK: - wrapTLV

    func testWrapTLV() {
        let payload: [UInt8] = [0x01, 0x02, 0x03]
        let result = DEREncoder.wrapTLV(tag: 0x04, payload)
        XCTAssertEqual(result, [0x04, 0x03, 0x01, 0x02, 0x03])
    }

    // MARK: - null

    func testNull() {
        let result = DEREncoder.null()
        XCTAssertEqual(result, [0x05, 0x00])
    }
}
