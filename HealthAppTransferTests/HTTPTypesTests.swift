import XCTest
@testable import HealthAppTransfer

final class HTTPTypesTests: XCTestCase {

    // MARK: - Helpers

    private func makeRawRequest(_ raw: String) -> Data {
        Data(raw.replacingOccurrences(of: "\n", with: "\r\n").utf8)
    }

    // MARK: - HTTPRequest.parse - Valid GET

    func testParseValidGETRequest() {
        let raw = makeRawRequest("GET /api/status HTTP/1.1\nHost: localhost\n\n")
        let request = HTTPRequest.parse(raw)

        XCTAssertNotNil(request)
        XCTAssertEqual(request?.method, .GET)
        XCTAssertEqual(request?.path, "/api/status")
        XCTAssertTrue(request?.queryParameters.isEmpty ?? false)
    }

    // MARK: - HTTPRequest.parse - Valid POST with body

    func testParseValidPOSTWithBody() {
        let raw = makeRawRequest("POST /api/pair HTTP/1.1\nContent-Type: application/json\n\n{\"code\":\"123456\"}")
        let request = HTTPRequest.parse(raw)

        XCTAssertNotNil(request)
        XCTAssertEqual(request?.method, .POST)
        XCTAssertEqual(request?.path, "/api/pair")
        XCTAssertNotNil(request?.body)

        let bodyString = String(data: request!.body!, encoding: .utf8)
        XCTAssertEqual(bodyString, "{\"code\":\"123456\"}")
    }

    // MARK: - HTTPRequest.parse - Query Parameters

    func testParseQueryParameters() {
        let raw = makeRawRequest("GET /api/data?type=stepCount&limit=100 HTTP/1.1\nHost: localhost\n\n")
        let request = HTTPRequest.parse(raw)

        XCTAssertNotNil(request)
        XCTAssertEqual(request?.queryParameters["type"], "stepCount")
        XCTAssertEqual(request?.queryParameters["limit"], "100")
    }

    // MARK: - HTTPRequest.parse - Headers

    func testParseHeaders() {
        let raw = makeRawRequest("GET /api/status HTTP/1.1\nHost: localhost\nAuthorization: Bearer token123\nX-Custom: value\n\n")
        let request = HTTPRequest.parse(raw)

        XCTAssertNotNil(request)
        XCTAssertEqual(request?.headers["Host"], "localhost")
        XCTAssertEqual(request?.headers["Authorization"], "Bearer token123")
        XCTAssertEqual(request?.headers["X-Custom"], "value")
    }

    // MARK: - Bearer Token Extraction

    func testBearerTokenExtraction() {
        let raw = makeRawRequest("GET /api/data HTTP/1.1\nAuthorization: Bearer mytoken\n\n")
        let request = HTTPRequest.parse(raw)

        XCTAssertEqual(request?.bearerToken, "mytoken")
    }

    func testBearerTokenWithoutPrefixReturnsNil() {
        let raw = makeRawRequest("GET /api/data HTTP/1.1\nAuthorization: Basic abc123\n\n")
        let request = HTTPRequest.parse(raw)

        XCTAssertNil(request?.bearerToken)
    }

    func testBearerTokenMissingHeaderReturnsNil() {
        let raw = makeRawRequest("GET /api/data HTTP/1.1\nHost: localhost\n\n")
        let request = HTTPRequest.parse(raw)

        XCTAssertNil(request?.bearerToken)
    }

    // MARK: - HTTPRequest.parse - Garbage Input

    func testParseGarbageReturnsNil() {
        let raw = Data("not an http request".utf8)
        XCTAssertNil(HTTPRequest.parse(raw))
    }

    func testParseEmptyDataReturnsNil() {
        XCTAssertNil(HTTPRequest.parse(Data()))
    }

    // MARK: - HTTPResponse.serialize

    func testSerializeProducesValidHTTP() {
        let response = HTTPResponse(
            statusCode: 200,
            statusMessage: "OK",
            headers: ["Content-Type": "application/json"],
            body: Data("{\"ok\":true}".utf8)
        )
        let data = response.serialize()
        let string = String(data: data, encoding: .utf8)!

        XCTAssertTrue(string.hasPrefix("HTTP/1.1 200 OK\r\n"))
        XCTAssertTrue(string.contains("Content-Type: application/json"))
        XCTAssertTrue(string.contains("Content-Length: 11"))
        XCTAssertTrue(string.hasSuffix("{\"ok\":true}"))
    }

    // MARK: - HTTPResponse.ok

    func testOkReturns200() {
        let response = HTTPResponse.ok()
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.statusMessage, "OK")
    }

    // MARK: - HTTPResponse.error

    func testErrorIncludesMessage() {
        let response = HTTPResponse.error(statusCode: 404, message: "Not found")
        XCTAssertEqual(response.statusCode, 404)
        XCTAssertNotNil(response.body)

        let bodyString = String(data: response.body!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("Not found"))
    }

    // MARK: - HTTPResponse.json

    func testJsonEncodesCodable() {
        struct TestPayload: Codable {
            let name: String
        }
        let response = HTTPResponse.json(TestPayload(name: "test"))
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers["Content-Type"], "application/json")

        let bodyString = String(data: response.body!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("\"name\":\"test\""))
    }

    // MARK: - DTO Codable Roundtrips

    func testAPIResponseCodableRoundtrip() throws {
        let original = APIResponse<String>(success: true, data: "hello", error: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(APIResponse<String>.self, from: data)
        XCTAssertEqual(decoded.success, true)
        XCTAssertEqual(decoded.data, "hello")
        XCTAssertNil(decoded.error)
    }

    func testServerStatusCodableRoundtrip() throws {
        let original = ServerStatus(status: "ready", version: "1.0", deviceName: "iPhone", availableTypes: 42)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ServerStatus.self, from: data)
        XCTAssertEqual(decoded.status, "ready")
        XCTAssertEqual(decoded.version, "1.0")
        XCTAssertEqual(decoded.deviceName, "iPhone")
        XCTAssertEqual(decoded.availableTypes, 42)
    }

    func testPairRequestCodableRoundtrip() throws {
        let original = PairRequest(code: "123456", deviceName: "Mac")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PairRequest.self, from: data)
        XCTAssertEqual(decoded.code, "123456")
        XCTAssertEqual(decoded.deviceName, "Mac")
    }

    func testPairResponseCodableRoundtrip() throws {
        let original = PairResponse(token: "abc", deviceID: "dev1", expiresIn: 3600)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PairResponse.self, from: data)
        XCTAssertEqual(decoded.token, "abc")
        XCTAssertEqual(decoded.deviceID, "dev1")
        XCTAssertEqual(decoded.expiresIn, 3600)
    }

    func testHealthTypesResponseCodableRoundtrip() throws {
        let info = HealthTypeInfo(identifier: "stepCount", displayName: "Step Count", sampleCount: 100)
        let original = HealthTypesResponse(types: [info])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HealthTypesResponse.self, from: data)
        XCTAssertEqual(decoded.types.count, 1)
        XCTAssertEqual(decoded.types[0].identifier, "stepCount")
        XCTAssertEqual(decoded.types[0].displayName, "Step Count")
        XCTAssertEqual(decoded.types[0].sampleCount, 100)
    }

    func testHealthTypeInfoCodableRoundtrip() throws {
        let original = HealthTypeInfo(identifier: "heartRate", displayName: "Heart Rate", sampleCount: 50)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HealthTypeInfo.self, from: data)
        XCTAssertEqual(decoded.identifier, original.identifier)
        XCTAssertEqual(decoded.displayName, original.displayName)
        XCTAssertEqual(decoded.sampleCount, original.sampleCount)
    }
}
