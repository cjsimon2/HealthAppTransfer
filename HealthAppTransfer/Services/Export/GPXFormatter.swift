import Foundation

// MARK: - GPX Route Point

/// A single GPS point extracted from an HKWorkoutRoute's CLLocation data.
struct GPXRoutePoint: Sendable {
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let timestamp: Date
    let heartRate: Double?
}

// MARK: - GPX Track

/// A workout track with metadata and route points for GPX export.
struct GPXTrack: Sendable {
    let name: String
    let startDate: Date
    let points: [GPXRoutePoint]
}

// MARK: - GPX Formatter

/// Exports workout route data as GPX 1.1 XML with trackpoints, elevation, and optional heart rate.
///
/// GPX output structure:
/// ```xml
/// <?xml version="1.0" encoding="UTF-8"?>
/// <gpx version="1.1" creator="HealthAppTransfer" ...>
///   <metadata><time>...</time></metadata>
///   <trk>
///     <name>Running</name>
///     <trkseg>
///       <trkpt lat="37.7749" lon="-122.4194">
///         <ele>10.5</ele>
///         <time>2024-06-15T10:30:00Z</time>
///         <extensions>
///           <gpxtpx:TrackPointExtension>
///             <gpxtpx:hr>145</gpxtpx:hr>
///           </gpxtpx:TrackPointExtension>
///         </extensions>
///       </trkpt>
///     </trkseg>
///   </trk>
/// </gpx>
/// ```
struct GPXFormatter: Sendable {

    let formatIdentifier = "gpx"

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Formats one or more workout tracks into GPX 1.1 XML data.
    func format(tracks: [GPXTrack]) throws -> Data {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="HealthAppTransfer"
          xmlns="http://www.topografix.com/GPX/1/1"
          xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
          <metadata>
            <time>\(Self.iso8601.string(from: Date()))</time>
          </metadata>
        """

        for track in tracks {
            xml += "\n  <trk>"
            xml += "\n    <name>\(escapeXML(track.name))</name>"
            xml += "\n    <trkseg>"

            for point in track.points {
                xml += trackpointXML(for: point)
            }

            xml += "\n    </trkseg>"
            xml += "\n  </trk>"
        }

        xml += "\n</gpx>\n"

        guard let data = xml.data(using: .utf8) else {
            throw GPXFormatterError.encodingFailed
        }
        return data
    }

    // MARK: - Private Helpers

    private func trackpointXML(for point: GPXRoutePoint) -> String {
        let lat = String(format: "%.7f", point.latitude)
        let lon = String(format: "%.7f", point.longitude)

        var xml = "\n      <trkpt lat=\"\(lat)\" lon=\"\(lon)\">"

        if let elevation = point.elevation {
            xml += "\n        <ele>\(String(format: "%.1f", elevation))</ele>"
        }

        xml += "\n        <time>\(Self.iso8601.string(from: point.timestamp))</time>"

        if let hr = point.heartRate {
            xml += "\n        <extensions>"
            xml += "\n          <gpxtpx:TrackPointExtension>"
            xml += "\n            <gpxtpx:hr>\(Int(hr.rounded()))</gpxtpx:hr>"
            xml += "\n          </gpxtpx:TrackPointExtension>"
            xml += "\n        </extensions>"
        }

        xml += "\n      </trkpt>"
        return xml
    }

    /// Escapes XML special characters in text content.
    private func escapeXML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - Errors

enum GPXFormatterError: LocalizedError {
    case encodingFailed
    case noRouteData

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode GPX as UTF-8"
        case .noRouteData:
            return "No route data available for this workout"
        }
    }
}
