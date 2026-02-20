import XCTest
@testable import HealthAppTransfer

final class ExportFormatterTests: XCTestCase {

    // MARK: - Helpers

    private let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private func makeSample(
        type: HealthDataType = .stepCount,
        value: Double? = 1000,
        unit: String? = "count",
        categoryValue: Int? = nil,
        workoutActivityType: UInt? = nil,
        workoutDuration: TimeInterval? = nil,
        workoutTotalEnergyBurned: Double? = nil,
        workoutTotalDistance: Double? = nil,
        correlationValues: [String: Double]? = nil,
        characteristicValue: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> HealthSampleDTO {
        let now = Date()
        return HealthSampleDTO(
            id: UUID(),
            type: type,
            startDate: startDate ?? now.addingTimeInterval(-3600),
            endDate: endDate ?? now,
            sourceName: "TestSource",
            sourceBundleIdentifier: "com.test.app",
            value: value,
            unit: unit,
            categoryValue: categoryValue,
            workoutActivityType: workoutActivityType,
            workoutDuration: workoutDuration,
            workoutTotalEnergyBurned: workoutTotalEnergyBurned,
            workoutTotalDistance: workoutTotalDistance,
            correlationValues: correlationValues,
            characteristicValue: characteristicValue,
            metadataJSON: nil
        )
    }

    private func decodeJSON(_ data: Data) throws -> Any {
        try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - JSONv1Formatter Tests

    func testV1FormatIdentifier() {
        let formatter = JSONv1Formatter()
        XCTAssertEqual(formatter.formatIdentifier, "json_v1")
    }

    func testV1EmptyArrayProducesEmptyJSON() throws {
        let formatter = JSONv1Formatter()
        let data = try formatter.format(samples: [], options: ExportOptions())
        let array = try decodeJSON(data) as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 0)
    }

    func testV1OutputIsFlatArray() throws {
        let formatter = JSONv1Formatter()
        let samples = [
            makeSample(type: .stepCount, value: 5000),
            makeSample(type: .heartRate, value: 72)
        ]

        let data = try formatter.format(samples: samples, options: ExportOptions())
        let array = try decodeJSON(data) as? [[String: Any]]

        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 2)
    }

    func testV1QuantitySampleFields() throws {
        let formatter = JSONv1Formatter()
        let sample = makeSample(type: .stepCount, value: 10000, unit: "count")
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let array = try decodeJSON(data) as? [[String: Any]]

        let first = try XCTUnwrap(array?.first)
        XCTAssertEqual(first["type"] as? String, "stepCount")
        XCTAssertEqual(first["value"] as? Double, 10000)
        XCTAssertEqual(first["unit"] as? String, "count")
        XCTAssertEqual(first["sourceName"] as? String, "TestSource")
        XCTAssertNotNil(first["startDate"] as? String)
        XCTAssertNotNil(first["endDate"] as? String)
    }

    func testV1CategorySampleFields() throws {
        let formatter = JSONv1Formatter()
        let sample = makeSample(
            type: .sleepAnalysis,
            value: nil,
            unit: nil,
            categoryValue: 1
        )
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let array = try decodeJSON(data) as? [[String: Any]]

        let first = try XCTUnwrap(array?.first)
        XCTAssertEqual(first["type"] as? String, "sleepAnalysis")
        XCTAssertEqual(first["categoryValue"] as? Int, 1)
    }

    func testV1WorkoutSampleFields() throws {
        let formatter = JSONv1Formatter()
        let sample = makeSample(
            type: .workout,
            value: nil,
            unit: nil,
            workoutActivityType: 37,
            workoutDuration: 1800,
            workoutTotalEnergyBurned: 350.5,
            workoutTotalDistance: 5000
        )
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let array = try decodeJSON(data) as? [[String: Any]]

        let first = try XCTUnwrap(array?.first)
        XCTAssertEqual(first["type"] as? String, "workout")
        XCTAssertEqual(first["workoutActivityType"] as? UInt, 37)
        XCTAssertEqual(first["workoutDuration"] as? Double, 1800)
        XCTAssertEqual(first["workoutTotalEnergyBurned"] as? Double, 350.5)
        XCTAssertEqual(first["workoutTotalDistance"] as? Double, 5000)
    }

    func testV1CorrelationSampleFields() throws {
        let formatter = JSONv1Formatter()
        let sample = makeSample(
            type: .bloodPressure,
            value: nil,
            unit: nil,
            correlationValues: ["systolic": 120, "diastolic": 80]
        )
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let array = try decodeJSON(data) as? [[String: Any]]

        let first = try XCTUnwrap(array?.first)
        XCTAssertEqual(first["type"] as? String, "bloodPressure")
        let corr = first["correlationValues"] as? [String: Double]
        XCTAssertEqual(corr?["systolic"], 120)
        XCTAssertEqual(corr?["diastolic"], 80)
    }

    func testV1DatesAreISO8601() throws {
        let formatter = JSONv1Formatter()
        let refDate = Date(timeIntervalSince1970: 1718400000) // 2024-06-15T00:00:00Z
        let sample = makeSample(startDate: refDate, endDate: refDate.addingTimeInterval(3600))
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let array = try decodeJSON(data) as? [[String: Any]]

        let first = try XCTUnwrap(array?.first)
        let startStr = try XCTUnwrap(first["startDate"] as? String)
        // ISO 8601 strings start with a year and contain "T"
        XCTAssertTrue(startStr.contains("T"), "Date should be ISO 8601 format")
        XCTAssertTrue(startStr.contains("2024"), "Date should contain the year")
    }

    func testV1PrettyPrintProducesIndentedOutput() throws {
        let formatter = JSONv1Formatter()
        let sample = makeSample()
        let options = ExportOptions(prettyPrint: true)
        let data = try formatter.format(samples: [sample], options: options)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(string.contains("\n"), "Pretty-printed JSON should contain newlines")
        XCTAssertTrue(string.contains("  "), "Pretty-printed JSON should contain indentation")
    }

    // MARK: - JSONv2Formatter Tests

    func testV2FormatIdentifier() {
        let formatter = JSONv2Formatter()
        XCTAssertEqual(formatter.formatIdentifier, "json_v2")
    }

    func testV2EmptyOutputHasMetadataAndEmptyData() throws {
        let formatter = JSONv2Formatter()
        let data = try formatter.format(samples: [], options: ExportOptions())
        let dict = try decodeJSON(data) as? [String: Any]

        XCTAssertNotNil(dict?["metadata"])
        XCTAssertNotNil(dict?["data"])

        let metadata = dict?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["sampleCount"] as? Int, 0)
        XCTAssertEqual(metadata?["formatVersion"] as? String, "2.0")

        let dataDict = dict?["data"] as? [String: Any]
        XCTAssertEqual(dataDict?.count, 0)
    }

    func testV2GroupsSamplesByType() throws {
        let formatter = JSONv2Formatter()
        let samples = [
            makeSample(type: .stepCount, value: 5000),
            makeSample(type: .stepCount, value: 3000),
            makeSample(type: .heartRate, value: 72),
        ]

        let data = try formatter.format(samples: samples, options: ExportOptions())
        let dict = try decodeJSON(data) as? [String: Any]
        let dataDict = try XCTUnwrap(dict?["data"] as? [String: Any])

        // Two type keys
        XCTAssertEqual(dataDict.count, 2)

        let steps = try XCTUnwrap(dataDict["stepCount"] as? [Any])
        XCTAssertEqual(steps.count, 2)

        let heartRates = try XCTUnwrap(dataDict["heartRate"] as? [Any])
        XCTAssertEqual(heartRates.count, 1)
    }

    func testV2MetadataContainsExportDate() throws {
        let formatter = JSONv2Formatter()
        let data = try formatter.format(samples: [makeSample()], options: ExportOptions())
        let dict = try decodeJSON(data) as? [String: Any]
        let metadata = try XCTUnwrap(dict?["metadata"] as? [String: Any])

        let exportDate = try XCTUnwrap(metadata["exportDate"] as? String)
        XCTAssertTrue(exportDate.contains("T"), "exportDate should be ISO 8601")
    }

    func testV2MetadataSampleCount() throws {
        let formatter = JSONv2Formatter()
        let samples = [
            makeSample(type: .stepCount),
            makeSample(type: .heartRate),
            makeSample(type: .bodyMass),
        ]
        let data = try formatter.format(samples: samples, options: ExportOptions())
        let dict = try decodeJSON(data) as? [String: Any]
        let metadata = try XCTUnwrap(dict?["metadata"] as? [String: Any])

        XCTAssertEqual(metadata["sampleCount"] as? Int, 3)
    }

    func testV2MetadataTypesListSorted() throws {
        let formatter = JSONv2Formatter()
        let samples = [
            makeSample(type: .heartRate),
            makeSample(type: .stepCount),
            makeSample(type: .bodyMass),
        ]
        let data = try formatter.format(samples: samples, options: ExportOptions())
        let dict = try decodeJSON(data) as? [String: Any]
        let metadata = try XCTUnwrap(dict?["metadata"] as? [String: Any])
        let types = try XCTUnwrap(metadata["types"] as? [String])

        XCTAssertEqual(types, types.sorted(), "Types should be sorted alphabetically")
        XCTAssertEqual(types.count, 3)
    }

    func testV2MetadataDateRange() throws {
        let formatter = JSONv2Formatter()
        let start = Date(timeIntervalSince1970: 1700000000)
        let end = Date(timeIntervalSince1970: 1700100000)
        let options = ExportOptions(startDate: start, endDate: end)

        let data = try formatter.format(samples: [makeSample()], options: options)
        let dict = try decodeJSON(data) as? [String: Any]
        let metadata = try XCTUnwrap(dict?["metadata"] as? [String: Any])
        let dateRange = try XCTUnwrap(metadata["dateRange"] as? [String: Any])

        XCTAssertNotNil(dateRange["start"] as? String)
        XCTAssertNotNil(dateRange["end"] as? String)
    }

    func testV2MetadataDeviceInfo() throws {
        let formatter = JSONv2Formatter()
        let options = ExportOptions(
            deviceName: "iPhone",
            deviceModel: "iPhone15,2",
            systemVersion: "17.5"
        )

        let data = try formatter.format(samples: [makeSample()], options: options)
        let dict = try decodeJSON(data) as? [String: Any]
        let metadata = try XCTUnwrap(dict?["metadata"] as? [String: Any])
        let device = try XCTUnwrap(metadata["device"] as? [String: Any])

        XCTAssertEqual(device["name"] as? String, "iPhone")
        XCTAssertEqual(device["model"] as? String, "iPhone15,2")
        XCTAssertEqual(device["systemVersion"] as? String, "17.5")
    }

    func testV2MetadataAppVersion() throws {
        let formatter = JSONv2Formatter()
        let options = ExportOptions(appVersion: "1.2.3")

        let data = try formatter.format(samples: [makeSample()], options: options)
        let dict = try decodeJSON(data) as? [String: Any]
        let metadata = try XCTUnwrap(dict?["metadata"] as? [String: Any])

        XCTAssertEqual(metadata["appVersion"] as? String, "1.2.3")
    }

    func testV2MetadataDeviceOmittedWhenNil() throws {
        let formatter = JSONv2Formatter()
        let data = try formatter.format(samples: [makeSample()], options: ExportOptions())
        let dict = try decodeJSON(data) as? [String: Any]
        let metadata = try XCTUnwrap(dict?["metadata"] as? [String: Any])

        // Device should be null/absent when no device info provided
        let device = metadata["device"]
        XCTAssertTrue(device == nil || device is NSNull)
    }

    func testV2HandlesAllSampleTypes() throws {
        let formatter = JSONv2Formatter()
        let samples = [
            // Quantity
            makeSample(type: .stepCount, value: 5000, unit: "count"),
            // Category
            makeSample(type: .sleepAnalysis, value: nil, unit: nil, categoryValue: 1),
            // Workout
            makeSample(
                type: .workout,
                value: nil,
                unit: nil,
                workoutActivityType: 37,
                workoutDuration: 1800
            ),
            // Correlation
            makeSample(
                type: .bloodPressure,
                value: nil,
                unit: nil,
                correlationValues: ["systolic": 120, "diastolic": 80]
            ),
        ]

        let data = try formatter.format(samples: samples, options: ExportOptions())
        let dict = try decodeJSON(data) as? [String: Any]
        let dataDict = try XCTUnwrap(dict?["data"] as? [String: Any])

        XCTAssertEqual(dataDict.count, 4)
        XCTAssertNotNil(dataDict["stepCount"])
        XCTAssertNotNil(dataDict["sleepAnalysis"])
        XCTAssertNotNil(dataDict["workout"])
        XCTAssertNotNil(dataDict["bloodPressure"])
    }

    func testV2DatesAreISO8601() throws {
        let formatter = JSONv2Formatter()
        let data = try formatter.format(samples: [makeSample()], options: ExportOptions())
        let dict = try decodeJSON(data) as? [String: Any]
        let metadata = try XCTUnwrap(dict?["metadata"] as? [String: Any])

        let exportDate = try XCTUnwrap(metadata["exportDate"] as? String)
        XCTAssertTrue(exportDate.contains("T"))
    }

    func testV2PrettyPrint() throws {
        let formatter = JSONv2Formatter()
        let options = ExportOptions(prettyPrint: true)
        let data = try formatter.format(samples: [makeSample()], options: options)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(string.contains("\n"))
        XCTAssertTrue(string.contains("  "))
    }

    // MARK: - Roundtrip (V1)

    func testV1RoundtripDecoding() throws {
        let formatter = JSONv1Formatter()
        let original = makeSample(type: .stepCount, value: 42, unit: "count")
        let data = try formatter.format(samples: [original], options: ExportOptions())

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([HealthSampleDTO].self, from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].type, .stepCount)
        XCTAssertEqual(decoded[0].value, 42)
        XCTAssertEqual(decoded[0].unit, "count")
        XCTAssertEqual(decoded[0].sourceName, "TestSource")
    }

    // MARK: - Shared Encoder Tests

    func testEncoderSortsKeys() throws {
        let formatter = JSONv1Formatter()
        let data = try formatter.format(samples: [makeSample()], options: ExportOptions())
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        // With sortedKeys, "endDate" should appear before "startDate"
        if let endIdx = string.range(of: "endDate"),
           let startIdx = string.range(of: "startDate") {
            XCTAssertTrue(endIdx.lowerBound < startIdx.lowerBound)
        }
    }
}
