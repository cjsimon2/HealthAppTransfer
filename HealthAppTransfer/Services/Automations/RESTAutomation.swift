import Foundation

// MARK: - REST Push Parameters

/// Sendable snapshot of AutomationConfiguration fields needed for a REST push.
/// Extract this on the main actor before crossing into the RESTAutomation actor.
struct RESTPushParameters: Sendable {
    let name: String
    let endpoint: String
    let exportFormat: String
    let incrementalOnly: Bool
    let lastTriggeredAt: Date?
    let enabledTypeRawValues: [String]
    let httpHeaders: [String: String]

    init(configuration: AutomationConfiguration) {
        self.name = configuration.name
        self.endpoint = configuration.endpoint ?? ""
        self.exportFormat = configuration.exportFormat
        self.incrementalOnly = configuration.incrementalOnly
        self.lastTriggeredAt = configuration.lastTriggeredAt
        self.enabledTypeRawValues = configuration.enabledTypeRawValues
        self.httpHeaders = configuration.httpHeaders
    }
}

// MARK: - REST Automation

/// Pushes health data to a user-configured HTTP endpoint via POST.
/// Supports JSON v1/v2 and CSV payloads, custom headers, incremental mode,
/// and retry with exponential backoff (3 attempts at 2/4/8s delays).
actor RESTAutomation {

    // MARK: - Dependencies

    private let healthKitService: HealthKitService
    private let session: URLSession

    // MARK: - Constants

    private static let maxRetries = 3
    private static let baseDelay: TimeInterval = 2 // seconds

    init(healthKitService: HealthKitService, session: URLSession = .shared) {
        self.healthKitService = healthKitService
        self.session = session
    }

    // MARK: - Execute

    /// Execute a REST push with the given parameters.
    /// Returns the HTTP status code on success.
    @discardableResult
    func execute(params: RESTPushParameters) async throws -> Int {
        guard let url = URL(string: params.endpoint), !params.endpoint.isEmpty else {
            throw RESTAutomationError.invalidEndpoint
        }

        // Fetch health data
        let samples = try await fetchSamples(params: params)

        guard !samples.isEmpty else {
            Loggers.automation.info("REST automation '\(params.name)': no samples to send")
            return 204
        }

        // Format payload
        let (body, contentType) = try formatPayload(samples: samples, format: params.exportFormat)

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        // Apply custom headers
        for (key, value) in params.httpHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body

        // Send with retry
        let statusCode = try await sendWithRetry(request: request)

        Loggers.automation.info("REST automation '\(params.name)': sent \(samples.count) samples, status \(statusCode)")
        return statusCode
    }

    // MARK: - Fetch Samples

    private func fetchSamples(params: RESTPushParameters) async throws -> [HealthSampleDTO] {
        let types = params.enabledTypeRawValues.compactMap { HealthDataType(rawValue: $0) }

        guard !types.isEmpty else {
            throw RESTAutomationError.noTypesConfigured
        }

        // Incremental mode: only fetch data since last push
        let startDate: Date? = params.incrementalOnly ? params.lastTriggeredAt : nil

        var allSamples: [HealthSampleDTO] = []
        for type in types {
            guard type.isSampleBased else { continue }
            let samples = try await healthKitService.fetchSampleDTOs(
                for: type,
                from: startDate
            )
            allSamples.append(contentsOf: samples)
        }

        return allSamples
    }

    // MARK: - Format Payload

    private func formatPayload(samples: [HealthSampleDTO], format: String) throws -> (Data, String) {
        let formatter: any ExportFormatter
        let contentType: String

        switch format {
        case "json_v1":
            formatter = JSONv1Formatter()
            contentType = "application/json"
        case "json_v2":
            formatter = JSONv2Formatter()
            contentType = "application/json"
        case "csv":
            formatter = CSVFormatter()
            contentType = "text/csv"
        default:
            formatter = JSONv2Formatter()
            contentType = "application/json"
        }

        let options = ExportOptions()
        let data = try formatter.format(samples: samples, options: options)
        return (data, contentType)
    }

    // MARK: - Retry Logic

    /// Sends the request with exponential backoff: 2s, 4s, 8s delays between attempts.
    private func sendWithRetry(request: URLRequest) async throws -> Int {
        var lastError: Error?

        for attempt in 0..<Self.maxRetries {
            do {
                let (_, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw RESTAutomationError.invalidResponse
                }

                let statusCode = httpResponse.statusCode

                // 2xx = success
                if (200..<300).contains(statusCode) {
                    return statusCode
                }

                // 4xx = client error, don't retry
                if (400..<500).contains(statusCode) {
                    throw RESTAutomationError.httpError(statusCode: statusCode)
                }

                // 5xx = server error, retry
                lastError = RESTAutomationError.httpError(statusCode: statusCode)
            } catch let error as RESTAutomationError {
                // Don't retry client errors
                if case .httpError(let code) = error, (400..<500).contains(code) {
                    throw error
                }
                lastError = error
            } catch {
                lastError = error
            }

            // Exponential backoff: 2^(attempt+1) seconds
            if attempt < Self.maxRetries - 1 {
                let delay = Self.baseDelay * pow(2.0, Double(attempt))
                Loggers.automation.warning("REST push attempt \(attempt + 1) failed, retrying in \(delay)s")
                try await Task.sleep(for: .seconds(delay))
            }
        }

        throw lastError ?? RESTAutomationError.allRetriesFailed
    }
}

// MARK: - Errors

enum RESTAutomationError: LocalizedError {
    case invalidEndpoint
    case noTypesConfigured
    case invalidResponse
    case httpError(statusCode: Int)
    case allRetriesFailed

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Invalid endpoint URL."
        case .noTypesConfigured:
            return "No health data types configured."
        case .invalidResponse:
            return "Server returned an invalid response."
        case .httpError(let statusCode):
            return "HTTP error \(statusCode)."
        case .allRetriesFailed:
            return "All retry attempts failed."
        }
    }
}
