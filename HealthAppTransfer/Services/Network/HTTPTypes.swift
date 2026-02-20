import Foundation

// MARK: - HTTP Types for Network Server

/// HTTP method.
enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case PUT
    case DELETE
    case OPTIONS
    case HEAD
}

/// Parsed HTTP request from raw data.
struct HTTPRequest: Sendable {
    let method: HTTPMethod
    let path: String
    let queryParameters: [String: String]
    let headers: [String: String]
    let body: Data?

    /// Extract the bearer token from the Authorization header.
    var bearerToken: String? {
        guard let auth = headers["authorization"] ?? headers["Authorization"],
              auth.lowercased().hasPrefix("bearer ") else {
            return nil
        }
        return String(auth.dropFirst(7))
    }

    /// Parse a raw HTTP request from data.
    static func parse(_ data: Data) -> HTTPRequest? {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        let lines = string.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }

        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return nil }

        guard let method = HTTPMethod(rawValue: parts[0].uppercased()) else { return nil }

        let fullPath = parts[1]
        let (path, queryParams) = parsePathAndQuery(fullPath)

        // Parse headers
        var headers: [String: String] = [:]
        var bodyStartIndex: Int?
        for (index, line) in lines.dropFirst().enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 2 // +1 for dropFirst, +1 for empty line
                break
            }
            let headerParts = line.split(separator: ":", maxSplits: 1)
            if headerParts.count == 2 {
                headers[String(headerParts[0]).trimmingCharacters(in: .whitespaces)] =
                    String(headerParts[1]).trimmingCharacters(in: .whitespaces)
            }
        }

        // Parse body
        var body: Data?
        if let startIndex = bodyStartIndex, startIndex < lines.count {
            let bodyString = lines[startIndex...].joined(separator: "\r\n")
            if !bodyString.isEmpty {
                body = bodyString.data(using: .utf8)
            }
        }

        return HTTPRequest(
            method: method,
            path: path,
            queryParameters: queryParams,
            headers: headers,
            body: body
        )
    }

    private static func parsePathAndQuery(_ fullPath: String) -> (String, [String: String]) {
        let components = fullPath.components(separatedBy: "?")
        let path = components[0]
        var params: [String: String] = [:]

        if components.count > 1 {
            let queryString = components[1]
            for pair in queryString.components(separatedBy: "&") {
                let kv = pair.components(separatedBy: "=")
                if kv.count == 2 {
                    params[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
                }
            }
        }

        return (path, params)
    }
}

/// HTTP response for writing back to the client.
struct HTTPResponse: Sendable {
    let statusCode: Int
    let statusMessage: String
    let headers: [String: String]
    let body: Data?

    /// Serialize to raw HTTP response data.
    func serialize() -> Data {
        var response = "HTTP/1.1 \(statusCode) \(statusMessage)\r\n"

        var allHeaders = headers
        if let body {
            allHeaders["Content-Length"] = "\(body.count)"
        } else {
            allHeaders["Content-Length"] = "0"
        }
        allHeaders["Connection"] = "close"

        for (key, value) in allHeaders {
            response += "\(key): \(value)\r\n"
        }
        response += "\r\n"

        var data = Data(response.utf8)
        if let body {
            data.append(body)
        }
        return data
    }

    // MARK: - Convenience Builders

    static func json(_ encodable: some Encodable, statusCode: Int = 200) -> HTTPResponse {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        guard let body = try? encoder.encode(encodable) else {
            return error(statusCode: 500, message: "Failed to encode response")
        }

        return HTTPResponse(
            statusCode: statusCode,
            statusMessage: statusMessage(for: statusCode),
            headers: ["Content-Type": "application/json"],
            body: body
        )
    }

    static func error(statusCode: Int, message: String) -> HTTPResponse {
        let body: [String: String] = ["error": message]
        let data = try? JSONSerialization.data(withJSONObject: body)

        return HTTPResponse(
            statusCode: statusCode,
            statusMessage: statusMessage(for: statusCode),
            headers: ["Content-Type": "application/json"],
            body: data
        )
    }

    static func ok() -> HTTPResponse {
        HTTPResponse(
            statusCode: 200,
            statusMessage: "OK",
            headers: ["Content-Type": "application/json"],
            body: Data("{}".utf8)
        )
    }

    private static func statusMessage(for code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 201: return "Created"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}

// MARK: - JSON Helpers

/// Generic API response wrapper.
struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    let success: Bool
    let data: T?
    let error: String?
}

/// Status endpoint response.
struct ServerStatus: Codable, Sendable {
    let status: String
    let version: String
    let deviceName: String
    let availableTypes: Int
}

/// Pairing request body.
struct PairRequest: Codable, Sendable {
    let code: String
    let deviceName: String?
}

/// Pairing response body.
struct PairResponse: Codable, Sendable {
    let token: String
    let deviceID: String?
    let expiresIn: TimeInterval?
}

/// Health types list response.
struct HealthTypesResponse: Codable, Sendable {
    let types: [HealthTypeInfo]
}

/// Info about an available health data type.
struct HealthTypeInfo: Codable, Sendable {
    let identifier: String
    let displayName: String
    let sampleCount: Int
}
