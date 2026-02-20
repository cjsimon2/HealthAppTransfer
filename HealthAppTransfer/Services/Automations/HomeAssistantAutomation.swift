import Foundation

// MARK: - Home Assistant Push Parameters

/// Sendable snapshot of AutomationConfiguration fields needed for a Home Assistant push.
/// Extract this on the main actor before crossing into the HomeAssistantAutomation actor.
struct HomeAssistantParameters: Sendable {
    let name: String
    let baseURL: String
    let accessToken: String
    let incrementalOnly: Bool
    let lastTriggeredAt: Date?
    let enabledTypeRawValues: [String]

    init(configuration: AutomationConfiguration, accessToken: String) {
        self.name = configuration.name
        self.baseURL = configuration.endpoint ?? ""
        self.accessToken = accessToken
        self.incrementalOnly = configuration.incrementalOnly
        self.lastTriggeredAt = configuration.lastTriggeredAt
        self.enabledTypeRawValues = configuration.enabledTypeRawValues
    }
}

// MARK: - Home Assistant Automation

/// Posts health data as sensor entity states to a Home Assistant instance via REST API.
/// Uses the /api/states/<entity_id> endpoint with long-lived access token auth.
actor HomeAssistantAutomation {

    // MARK: - Dependencies

    private let healthKitService: HealthKitService
    private let session: URLSession

    // MARK: - Constants

    /// Keychain key prefix for storing HA access tokens.
    static let keychainKeyPrefix = "ha_token_"

    init(healthKitService: HealthKitService, session: URLSession = .shared) {
        self.healthKitService = healthKitService
        self.session = session
    }

    // MARK: - Connection Test

    /// Validates that the HA instance is reachable and the token is valid.
    /// Calls GET /api/ which returns {"message": "API running."} on success.
    func testConnection(baseURL: String, accessToken: String) async throws {
        let url = try buildURL(baseURL: baseURL, path: "/api/")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HomeAssistantError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw HomeAssistantError.unauthorized
            }
            throw HomeAssistantError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Execute

    /// Push health data as sensor states to Home Assistant.
    func execute(params: HomeAssistantParameters) async throws {
        guard !params.baseURL.isEmpty else {
            throw HomeAssistantError.invalidURL
        }

        guard !params.accessToken.isEmpty else {
            throw HomeAssistantError.missingToken
        }

        // Fetch health data
        let samples = try await fetchSamples(params: params)

        guard !samples.isEmpty else {
            Loggers.automation.info("HA automation '\(params.name)': no samples to send")
            return
        }

        // Group samples by type and push the latest value for each as a sensor state
        let grouped = Dictionary(grouping: samples) { $0.type }

        for (type, typeSamples) in grouped {
            guard let latest = typeSamples.max(by: { $0.endDate < $1.endDate }) else { continue }
            try await postSensorState(
                baseURL: params.baseURL,
                accessToken: params.accessToken,
                type: type,
                sample: latest
            )
        }

        Loggers.automation.info("HA automation '\(params.name)': updated \(grouped.count) sensors from \(samples.count) samples")
    }

    // MARK: - Post Sensor State

    /// Posts a single sensor state to /api/states/<entity_id>.
    private func postSensorState(
        baseURL: String,
        accessToken: String,
        type: HealthDataType,
        sample: HealthSampleDTO
    ) async throws {
        let entityId = Self.entityId(for: type)
        let url = try buildURL(baseURL: baseURL, path: "/api/states/\(entityId)")

        let state = sensorState(for: type, sample: sample)
        let attributes = sensorAttributes(for: type, sample: sample)

        let body: [String: Any] = [
            "state": state,
            "attributes": attributes
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: body, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HomeAssistantError.invalidResponse
        }

        // HA returns 200 (updated) or 201 (created)
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw HomeAssistantError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Fetch Samples

    private func fetchSamples(params: HomeAssistantParameters) async throws -> [HealthSampleDTO] {
        let types = params.enabledTypeRawValues.compactMap { HealthDataType(rawValue: $0) }

        guard !types.isEmpty else {
            throw HomeAssistantError.noTypesConfigured
        }

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

    // MARK: - Entity Naming

    /// Converts a HealthDataType to a Home Assistant entity ID.
    /// e.g. `.stepCount` -> "sensor.health_step_count"
    static func entityId(for type: HealthDataType) -> String {
        // Convert camelCase rawValue to snake_case
        let snakeCase = type.rawValue.reduce(into: "") { result, char in
            if char.isUppercase && !result.isEmpty {
                result.append("_")
            }
            result.append(char.lowercased())
        }
        return "sensor.health_\(snakeCase)"
    }

    // MARK: - Sensor State

    /// Returns the state value string for the sensor.
    private func sensorState(for type: HealthDataType, sample: HealthSampleDTO) -> String {
        if let value = sample.value {
            // Format integers without decimal places
            if value.truncatingRemainder(dividingBy: 1) == 0 && value < 1_000_000 {
                return String(Int(value))
            }
            return String(format: "%.2f", value)
        }

        if let categoryValue = sample.categoryValue {
            return String(categoryValue)
        }

        if let duration = sample.workoutDuration {
            return String(format: "%.0f", duration)
        }

        return "unknown"
    }

    /// Returns HA-compatible attributes including unit_of_measurement, device_class, and state_class.
    private func sensorAttributes(for type: HealthDataType, sample: HealthSampleDTO) -> [String: Any] {
        var attrs: [String: Any] = [
            "friendly_name": type.displayName,
            "source": sample.sourceName,
            "last_updated": ISO8601DateFormatter().string(from: sample.endDate)
        ]

        if let unit = sample.unit {
            attrs["unit_of_measurement"] = haUnitString(unit)
        }

        if let deviceClass = haDeviceClass(for: type) {
            attrs["device_class"] = deviceClass
        }

        if let stateClass = haStateClass(for: type) {
            attrs["state_class"] = stateClass
        }

        return attrs
    }

    // MARK: - HA Unit Mapping

    /// Maps HealthKit unit strings to Home Assistant unit strings.
    private func haUnitString(_ hkUnit: String) -> String {
        switch hkUnit {
        case "count": return "steps"
        case "kcal": return "kcal"
        case "count/min", "bpm": return "bpm"
        case "m": return "m"
        case "km": return "km"
        case "mi": return "mi"
        case "degC": return "\u{00B0}C"
        case "degF": return "\u{00B0}F"
        case "%": return "%"
        case "mg/dL": return "mg/dL"
        case "mmol/L": return "mmol/L"
        case "mmHg": return "mmHg"
        case "kg": return "kg"
        case "lb": return "lb"
        case "cm": return "cm"
        case "min": return "min"
        case "ms": return "ms"
        case "g": return "g"
        case "mg": return "mg"
        case "mcg": return "\u{00B5}g"
        case "mL": return "mL"
        case "L/min": return "L/min"
        case "dBASPL": return "dB"
        case "W": return "W"
        case "count/s": return "count/s"
        default: return hkUnit
        }
    }

    /// Returns the HA device_class for types that have a standard mapping.
    private func haDeviceClass(for type: HealthDataType) -> String? {
        switch type {
        case .bodyTemperature, .basalBodyTemperature, .appleSleepingWristTemperature, .waterTemperature:
            return "temperature"
        case .bodyMass, .leanBodyMass:
            return "weight"
        case .distanceWalkingRunning, .distanceCycling, .distanceSwimming,
             .distanceWheelchair, .distanceDownhillSnowSports, .sixMinuteWalkTestDistance:
            return "distance"
        case .appleExerciseTime, .appleStandTime, .appleMoveTime:
            return "duration"
        case .cyclingPower, .cyclingFunctionalThresholdPower, .runningPower:
            return "power"
        case .cyclingSpeed, .runningSpeed, .walkingSpeed, .stairAscentSpeed, .stairDescentSpeed:
            return "speed"
        default:
            return nil
        }
    }

    /// Returns the HA state_class for cumulative vs measurement types.
    private func haStateClass(for type: HealthDataType) -> String? {
        switch type {
        case .stepCount, .flightsClimbed, .activeEnergyBurned, .basalEnergyBurned,
             .pushCount, .swimmingStrokeCount, .distanceWalkingRunning, .distanceCycling,
             .distanceSwimming, .distanceWheelchair, .distanceDownhillSnowSports,
             .appleExerciseTime, .appleStandTime, .appleMoveTime,
             .dietaryEnergyConsumed, .dietaryWater, .dietaryCarbohydrates, .dietaryProtein,
             .dietaryFatTotal, .dietarySugar, .dietaryFiber, .dietarySodium, .dietaryCaffeine,
             .numberOfTimesFallen, .inhalerUsage:
            return "total_increasing"
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage,
             .heartRateVariabilitySDNN, .oxygenSaturation, .bodyTemperature,
             .bloodPressureSystolic, .bloodPressureDiastolic, .respiratoryRate,
             .bodyMass, .bodyMassIndex, .bodyFatPercentage, .bloodGlucose,
             .vo2Max, .walkingSpeed, .cyclingSpeed, .runningSpeed:
            return "measurement"
        default:
            return nil
        }
    }

    // MARK: - URL Helper

    private func buildURL(baseURL: String, path: String) throws -> URL {
        // Strip trailing slash from base URL
        let cleanBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL

        guard let url = URL(string: cleanBase + path) else {
            throw HomeAssistantError.invalidURL
        }
        return url
    }
}

// MARK: - Errors

enum HomeAssistantError: LocalizedError {
    case invalidURL
    case missingToken
    case unauthorized
    case invalidResponse
    case httpError(statusCode: Int)
    case noTypesConfigured

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Home Assistant URL."
        case .missingToken:
            return "No access token provided."
        case .unauthorized:
            return "Invalid or expired access token."
        case .invalidResponse:
            return "Home Assistant returned an invalid response."
        case .httpError(let statusCode):
            return "HTTP error \(statusCode)."
        case .noTypesConfigured:
            return "No health data types configured."
        }
    }
}
