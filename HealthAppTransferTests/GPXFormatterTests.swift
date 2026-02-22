import XCTest
@testable import HealthAppTransfer

final class GPXFormatterTests: XCTestCase {

    // MARK: - Helpers

    private let formatter = GPXFormatter()

    private func makePoint(
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        elevation: Double? = 10.5,
        timestamp: Date = Date(),
        heartRate: Double? = nil
    ) -> GPXRoutePoint {
        GPXRoutePoint(
            latitude: latitude,
            longitude: longitude,
            elevation: elevation,
            timestamp: timestamp,
            heartRate: heartRate
        )
    }

    private func makeTrack(
        name: String = "Running",
        startDate: Date = Date(),
        points: [GPXRoutePoint]? = nil
    ) -> GPXTrack {
        GPXTrack(
            name: name,
            startDate: startDate,
            points: points ?? [makePoint()]
        )
    }

    private func gpxString(from data: Data) -> String {
        String(data: data, encoding: .utf8)!
    }

    // MARK: - Format Identifier

    func testFormatIdentifier() {
        XCTAssertEqual(formatter.formatIdentifier, "gpx")
    }

    // MARK: - XML Structure

    func testOutputStartsWithXMLDeclaration() throws {
        let data = try formatter.format(tracks: [makeTrack()])
        let xml = gpxString(from: data)
        XCTAssertTrue(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    }

    func testOutputContainsGPXRootElement() throws {
        let data = try formatter.format(tracks: [makeTrack()])
        let xml = gpxString(from: data)
        XCTAssertTrue(xml.contains("<gpx version=\"1.1\""))
        XCTAssertTrue(xml.contains("</gpx>"))
    }

    func testOutputContainsGPXNamespaces() throws {
        let data = try formatter.format(tracks: [makeTrack()])
        let xml = gpxString(from: data)
        XCTAssertTrue(xml.contains("xmlns=\"http://www.topografix.com/GPX/1/1\""))
        XCTAssertTrue(xml.contains("xmlns:gpxtpx=\"http://www.garmin.com/xmlschemas/TrackPointExtension/v1\""))
    }

    func testOutputContainsMetadataTime() throws {
        let data = try formatter.format(tracks: [makeTrack()])
        let xml = gpxString(from: data)
        XCTAssertTrue(xml.contains("<metadata>"))
        XCTAssertTrue(xml.contains("<time>"))
        XCTAssertTrue(xml.contains("</metadata>"))
    }

    // MARK: - Track Structure

    func testTrackContainsTrkElement() throws {
        let data = try formatter.format(tracks: [makeTrack(name: "Morning Run")])
        let xml = gpxString(from: data)
        XCTAssertTrue(xml.contains("<trk>"))
        XCTAssertTrue(xml.contains("<name>Morning Run</name>"))
        XCTAssertTrue(xml.contains("<trkseg>"))
        XCTAssertTrue(xml.contains("</trkseg>"))
        XCTAssertTrue(xml.contains("</trk>"))
    }

    func testMultipleTracks() throws {
        let tracks = [
            makeTrack(name: "Track 1"),
            makeTrack(name: "Track 2"),
        ]
        let data = try formatter.format(tracks: tracks)
        let xml = gpxString(from: data)

        let trkCount = xml.components(separatedBy: "<trk>").count - 1
        XCTAssertEqual(trkCount, 2)
        XCTAssertTrue(xml.contains("<name>Track 1</name>"))
        XCTAssertTrue(xml.contains("<name>Track 2</name>"))
    }

    // MARK: - Trackpoint Elements

    func testTrackpointContainsLatLon() throws {
        let point = makePoint(latitude: 37.7749, longitude: -122.4194)
        let track = makeTrack(points: [point])
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertTrue(xml.contains("lat=\"37.7749000\""))
        XCTAssertTrue(xml.contains("lon=\"-122.4194000\""))
    }

    func testTrackpointContainsElevation() throws {
        let point = makePoint(elevation: 42.3)
        let track = makeTrack(points: [point])
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertTrue(xml.contains("<ele>42.3</ele>"))
    }

    func testTrackpointOmitsElevationWhenNil() throws {
        let point = makePoint(elevation: nil)
        let track = makeTrack(points: [point])
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertFalse(xml.contains("<ele>"))
    }

    func testTrackpointContainsTimestamp() throws {
        let refDate = Date(timeIntervalSince1970: 1718400000)
        let point = makePoint(timestamp: refDate)
        let track = makeTrack(points: [point])
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let expected = "<time>\(iso.string(from: refDate))</time>"
        XCTAssertTrue(xml.contains(expected), "Expected \(expected) in GPX output")
    }

    // MARK: - Heart Rate Extension

    func testTrackpointContainsHeartRateExtension() throws {
        let point = makePoint(heartRate: 145)
        let track = makeTrack(points: [point])
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertTrue(xml.contains("<extensions>"))
        XCTAssertTrue(xml.contains("<gpxtpx:TrackPointExtension>"))
        XCTAssertTrue(xml.contains("<gpxtpx:hr>145</gpxtpx:hr>"))
        XCTAssertTrue(xml.contains("</gpxtpx:TrackPointExtension>"))
        XCTAssertTrue(xml.contains("</extensions>"))
    }

    func testTrackpointOmitsHeartRateWhenNil() throws {
        let point = makePoint(heartRate: nil)
        let track = makeTrack(points: [point])
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertFalse(xml.contains("<extensions>"))
        XCTAssertFalse(xml.contains("gpxtpx:hr"))
    }

    // MARK: - XML Escaping

    func testTrackNameWithSpecialCharsIsEscaped() throws {
        let track = makeTrack(name: "Run <5K> & Hills")
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertTrue(xml.contains("<name>Run &lt;5K&gt; &amp; Hills</name>"))
    }

    // MARK: - Empty Tracks

    func testEmptyTracksListProducesValidGPX() throws {
        let data = try formatter.format(tracks: [])
        let xml = gpxString(from: data)

        XCTAssertTrue(xml.contains("<gpx"))
        XCTAssertTrue(xml.contains("</gpx>"))
        XCTAssertFalse(xml.contains("<trk>"))
    }

    func testTrackWithNoPointsProducesEmptySegment() throws {
        let track = GPXTrack(name: "Empty", startDate: Date(), points: [])
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertTrue(xml.contains("<trkseg>"))
        XCTAssertTrue(xml.contains("</trkseg>"))
        XCTAssertFalse(xml.contains("<trkpt"))
    }

    // MARK: - Multiple Points

    func testMultiplePointsInTrack() throws {
        let points = [
            makePoint(latitude: 37.7749, longitude: -122.4194, elevation: 10),
            makePoint(latitude: 37.7750, longitude: -122.4195, elevation: 11),
            makePoint(latitude: 37.7751, longitude: -122.4196, elevation: 12),
        ]
        let track = makeTrack(points: points)
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        let trkptCount = xml.components(separatedBy: "<trkpt").count - 1
        XCTAssertEqual(trkptCount, 3)
    }

    // MARK: - Mixed Heart Rate Points

    func testMixedHeartRatePointsRenderCorrectly() throws {
        let base = Date()
        let points = [
            makePoint(latitude: 37.7749, longitude: -122.4194, elevation: 10, timestamp: base, heartRate: 120),
            makePoint(latitude: 37.7750, longitude: -122.4195, elevation: 11, timestamp: base.addingTimeInterval(5), heartRate: nil),
            makePoint(latitude: 37.7751, longitude: -122.4196, elevation: 12, timestamp: base.addingTimeInterval(10), heartRate: 155),
        ]
        let track = makeTrack(points: points)
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertTrue(xml.contains("<gpxtpx:hr>120</gpxtpx:hr>"))
        XCTAssertTrue(xml.contains("<gpxtpx:hr>155</gpxtpx:hr>"))

        // Count HR extensions — should be exactly 2 (not 3)
        let hrCount = xml.components(separatedBy: "<gpxtpx:hr>").count - 1
        XCTAssertEqual(hrCount, 2, "Only points with heart rate should have HR extensions")
    }

    func testHeartRateRoundsToInteger() throws {
        let point = makePoint(heartRate: 142.7)
        let track = makeTrack(points: [point])
        let data = try formatter.format(tracks: [track])
        let xml = gpxString(from: data)

        XCTAssertTrue(xml.contains("<gpxtpx:hr>143</gpxtpx:hr>"), "HR should be rounded to nearest integer")
    }
}
