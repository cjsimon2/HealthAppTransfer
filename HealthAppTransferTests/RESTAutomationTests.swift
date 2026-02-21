import XCTest
@testable import HealthAppTransfer

// MARK: - Mock URL Protocol

final class MockURLProtocol: URLProtocol {

    /// Map of URL → (statusCode, responseData, error)
    nonisolated(unsafe) static var responses: [String: (Int, Data?, Error?)] = [:]

    /// Record of requests made
    nonisolated(unsafe) static var requestLog: [URLRequest] = []

    static func reset() {
        responses = [:]
        requestLog = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        var captured = request
        // URLSession moves httpBody to httpBodyStream; read it back
        if captured.httpBody == nil, let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: 4096)
                if read > 0 { data.append(buffer, count: read) } else { break }
            }
            stream.close()
            captured.httpBody = data
        }
        MockURLProtocol.requestLog.append(captured)

        let urlString = request.url?.absoluteString ?? ""

        if let (statusCode, data, error) = MockURLProtocol.responses[urlString] {
            if let error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } else {
            // Default: 200 OK
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

// MARK: - Tests

final class RESTAutomationTests: XCTestCase {

    private var mockSession: URLSession!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        mockSession = nil
        super.tearDown()
    }

    // MARK: - RESTPushParameters

    func testRESTPushParametersProperties() {
        // RESTPushParameters requires AutomationConfiguration (SwiftData model)
        // which can't be created outside a model context.
        // Test the struct's Sendable conformance at compile-time only.
        // The actual struct is tested indirectly via RESTAutomation integration.
        let _: any Sendable.Type = RESTPushParameters.self
    }

    // MARK: - RESTAutomationError

    func testInvalidEndpointError() {
        let error = RESTAutomationError.invalidEndpoint
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("endpoint"))
    }

    func testNoTypesConfiguredError() {
        let error = RESTAutomationError.noTypesConfigured
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("type"))
    }

    func testInvalidResponseError() {
        let error = RESTAutomationError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
    }

    func testHTTPError() {
        let error = RESTAutomationError.httpError(statusCode: 404)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("404"))
    }

    func testAllRetriesFailedError() {
        let error = RESTAutomationError.allRetriesFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("retry"))
    }

    // MARK: - Export Format Selection

    func testJSONv1FormatterIdentifier() {
        let formatter = JSONv1Formatter()
        XCTAssertEqual(formatter.formatIdentifier, "json_v1")
    }

    func testJSONv2FormatterIdentifier() {
        let formatter = JSONv2Formatter()
        XCTAssertEqual(formatter.formatIdentifier, "json_v2")
    }

    func testCSVFormatterIdentifier() {
        let formatter = CSVFormatter()
        XCTAssertEqual(formatter.formatIdentifier, "csv")
    }

    // MARK: - Export Format Payload Tests

    func testJSONv1ProducesValidArray() throws {
        let formatter = JSONv1Formatter()
        let samples = [makeSampleDTO(type: .stepCount, value: 5000, unit: "count")]
        let data = try formatter.format(samples: samples, options: ExportOptions())

        let array = try JSONSerialization.jsonObject(with: data) as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 1)
    }

    func testJSONv2ProducesValidEnvelope() throws {
        let formatter = JSONv2Formatter()
        let samples = [makeSampleDTO(type: .stepCount, value: 5000, unit: "count")]
        let data = try formatter.format(samples: samples, options: ExportOptions())

        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(dict?["metadata"])
        XCTAssertNotNil(dict?["data"])
    }

    func testCSVProducesValidOutput() throws {
        let formatter = CSVFormatter()
        let samples = [makeSampleDTO(type: .stepCount, value: 5000, unit: "count")]
        let data = try formatter.format(samples: samples, options: ExportOptions())

        let string = String(data: data, encoding: .utf8)!
        let lines = string.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 2) // header + 1 data row
    }

    // MARK: - MockURLProtocol Verification

    func testMockURLProtocolReturnsConfiguredResponse() async throws {
        MockURLProtocol.responses["https://example.com/test"] = (201, "OK".data(using: .utf8), nil)

        let (_, response) = try await mockSession.data(from: URL(string: "https://example.com/test")!)
        let httpResponse = response as! HTTPURLResponse

        XCTAssertEqual(httpResponse.statusCode, 201)
    }

    func testMockURLProtocolReturnsError() async {
        let testError = NSError(domain: "test", code: 42, userInfo: nil)
        MockURLProtocol.responses["https://example.com/error"] = (0, nil, testError)

        do {
            _ = try await mockSession.data(from: URL(string: "https://example.com/error")!)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual((error as NSError).code, 42)
        }
    }

    func testMockURLProtocolRecordsRequests() async throws {
        MockURLProtocol.responses["https://example.com/log"] = (200, nil, nil)

        _ = try await mockSession.data(from: URL(string: "https://example.com/log")!)

        XCTAssertEqual(MockURLProtocol.requestLog.count, 1)
        XCTAssertEqual(MockURLProtocol.requestLog.first?.url?.absoluteString, "https://example.com/log")
    }

    func testMockURLProtocolDefaultsTo200() async throws {
        // No configured response for this URL
        let (_, response) = try await mockSession.data(from: URL(string: "https://example.com/default")!)
        let httpResponse = response as! HTTPURLResponse

        XCTAssertEqual(httpResponse.statusCode, 200)
    }

    // MARK: - HTTP Request Building

    func testPOSTRequestWithJSONContentType() async throws {
        MockURLProtocol.responses["https://example.com/api"] = (200, nil, nil)

        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        _ = try await mockSession.data(for: request)

        let recorded = MockURLProtocol.requestLog.first
        XCTAssertEqual(recorded?.httpMethod, "POST")
        XCTAssertEqual(recorded?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testCustomHeadersApplied() async throws {
        MockURLProtocol.responses["https://example.com/api"] = (200, nil, nil)

        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "POST"
        request.setValue("Bearer mytoken", forHTTPHeaderField: "Authorization")
        request.setValue("custom-value", forHTTPHeaderField: "X-Custom-Header")

        _ = try await mockSession.data(for: request)

        let recorded = MockURLProtocol.requestLog.first
        XCTAssertEqual(recorded?.value(forHTTPHeaderField: "Authorization"), "Bearer mytoken")
        XCTAssertEqual(recorded?.value(forHTTPHeaderField: "X-Custom-Header"), "custom-value")
    }

    // MARK: - HTTP Status Code Handling

    func testSuccessStatusCodes() async throws {
        for statusCode in [200, 201, 202, 204] {
            MockURLProtocol.reset()
            MockURLProtocol.responses["https://example.com/api"] = (statusCode, nil, nil)

            let (_, response) = try await mockSession.data(from: URL(string: "https://example.com/api")!)
            let httpResponse = response as! HTTPURLResponse

            XCTAssertEqual(httpResponse.statusCode, statusCode)
        }
    }

    func testClientErrorStatusCodes() async throws {
        for statusCode in [400, 401, 403, 404, 422] {
            MockURLProtocol.reset()
            MockURLProtocol.responses["https://example.com/api"] = (statusCode, nil, nil)

            let (_, response) = try await mockSession.data(from: URL(string: "https://example.com/api")!)
            let httpResponse = response as! HTTPURLResponse

            // URLSession doesn't throw for non-2xx, caller must check
            XCTAssertEqual(httpResponse.statusCode, statusCode)
        }
    }

    func testServerErrorStatusCodes() async throws {
        for statusCode in [500, 502, 503] {
            MockURLProtocol.reset()
            MockURLProtocol.responses["https://example.com/api"] = (statusCode, nil, nil)

            let (_, response) = try await mockSession.data(from: URL(string: "https://example.com/api")!)
            let httpResponse = response as! HTTPURLResponse

            XCTAssertEqual(httpResponse.statusCode, statusCode)
        }
    }

    // MARK: - Payload Format Integration

    func testJSONv1PayloadSentCorrectly() async throws {
        MockURLProtocol.responses["https://example.com/api"] = (200, nil, nil)

        let samples = [makeSampleDTO(type: .stepCount, value: 10000, unit: "count")]
        let formatter = JSONv1Formatter()
        let body = try formatter.format(samples: samples, options: ExportOptions())

        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        _ = try await mockSession.data(for: request)

        let recorded = MockURLProtocol.requestLog.first
        XCTAssertNotNil(recorded?.httpBody)

        // Verify the body is valid JSON array
        if let bodyData = recorded?.httpBody {
            let parsed = try JSONSerialization.jsonObject(with: bodyData) as? [Any]
            XCTAssertNotNil(parsed)
            XCTAssertEqual(parsed?.count, 1)
        }
    }

    func testCSVPayloadSentCorrectly() async throws {
        MockURLProtocol.responses["https://example.com/api"] = (200, nil, nil)

        let samples = [makeSampleDTO(type: .heartRate, value: 72, unit: "count/min")]
        let formatter = CSVFormatter()
        let body = try formatter.format(samples: samples, options: ExportOptions())

        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "POST"
        request.setValue("text/csv", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        _ = try await mockSession.data(for: request)

        let recorded = MockURLProtocol.requestLog.first
        XCTAssertEqual(recorded?.value(forHTTPHeaderField: "Content-Type"), "text/csv")
        if let bodyData = recorded?.httpBody {
            let csvString = String(data: bodyData, encoding: .utf8)!
            XCTAssertTrue(csvString.contains("heartRate"))
        }
    }

    // MARK: - HealthSampleDTO Helpers

    func testHealthSampleDTOEncodeDecodeRoundtrip() throws {
        let dto = makeSampleDTO(type: .stepCount, value: 5000, unit: "count")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HealthSampleDTO.self, from: data)

        XCTAssertEqual(decoded.type, .stepCount)
        XCTAssertEqual(decoded.value, 5000)
        XCTAssertEqual(decoded.unit, "count")
    }

    // MARK: - Helpers

    private func makeSampleDTO(
        type: HealthDataType,
        value: Double? = nil,
        unit: String? = nil
    ) -> HealthSampleDTO {
        HealthSampleDTO(
            id: UUID(),
            type: type,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            sourceName: "TestSource",
            sourceBundleIdentifier: "com.test.app",
            value: value,
            unit: unit,
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: nil,
            characteristicValue: nil,
            metadataJSON: nil
        )
    }
}

