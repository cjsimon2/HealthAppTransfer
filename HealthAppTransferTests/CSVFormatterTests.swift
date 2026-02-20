import XCTest
@testable import HealthAppTransfer

final class CSVFormatterTests: XCTestCase {

    // MARK: - Helpers

    private let formatter = CSVFormatter()

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
        sourceName: String = "TestSource",
        metadataJSON: String? = nil
    ) -> HealthSampleDTO {
        let now = Date()
        return HealthSampleDTO(
            id: UUID(),
            type: type,
            startDate: now.addingTimeInterval(-3600),
            endDate: now,
            sourceName: sourceName,
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
            metadataJSON: metadataJSON
        )
    }

    private func csvString(from data: Data) -> String {
        String(data: data, encoding: .utf8)!
    }

    private func csvLines(from data: Data) -> [String] {
        csvString(from: data).components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    // MARK: - Format Identifier

    func testFormatIdentifier() {
        XCTAssertEqual(formatter.formatIdentifier, "csv")
    }

    // MARK: - Header Row

    func testHeaderRow() throws {
        let data = try formatter.format(samples: [], options: ExportOptions())
        let lines = csvLines(from: data)

        XCTAssertEqual(lines.count, 1, "Empty samples should produce only a header row")

        let expectedHeader = "id,type,startDate,endDate,sourceName,sourceBundleIdentifier,value,unit,categoryValue,workoutActivityType,workoutDuration,workoutTotalEnergyBurned,workoutTotalDistance,correlationValues,characteristicValue,metadata"
        XCTAssertEqual(lines[0], expectedHeader)
    }

    // MARK: - Basic Output

    func testSingleSampleProducesTwoLines() throws {
        let sample = makeSample()
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let lines = csvLines(from: data)

        XCTAssertEqual(lines.count, 2, "One sample = header + one data row")
    }

    func testMultipleSamplesProduceCorrectLineCount() throws {
        let samples = [
            makeSample(type: .stepCount, value: 5000),
            makeSample(type: .heartRate, value: 72),
            makeSample(type: .bodyMass, value: 75.5),
        ]
        let data = try formatter.format(samples: samples, options: ExportOptions())
        let lines = csvLines(from: data)

        XCTAssertEqual(lines.count, 4, "Three samples = header + three data rows")
    }

    // MARK: - Field Values

    func testQuantitySampleFields() throws {
        let sample = makeSample(type: .stepCount, value: 10000, unit: "count")
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let lines = csvLines(from: data)
        let fields = lines[1].components(separatedBy: ",")

        // type is field index 1
        XCTAssertEqual(fields[1], "stepCount")
        // value is field index 6
        XCTAssertEqual(fields[6], "10000.0")
        // unit is field index 7
        XCTAssertEqual(fields[7], "count")
    }

    func testCategorySampleFields() throws {
        let sample = makeSample(type: .sleepAnalysis, value: nil, unit: nil, categoryValue: 1)
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let lines = csvLines(from: data)
        let fields = lines[1].components(separatedBy: ",")

        XCTAssertEqual(fields[1], "sleepAnalysis")
        // value should be empty
        XCTAssertEqual(fields[6], "")
        // categoryValue is field index 8
        XCTAssertEqual(fields[8], "1")
    }

    func testWorkoutSampleFields() throws {
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
        let lines = csvLines(from: data)
        let fields = lines[1].components(separatedBy: ",")

        XCTAssertEqual(fields[1], "workout")
        XCTAssertEqual(fields[9], "37")       // workoutActivityType
        XCTAssertEqual(fields[10], "1800.0")  // workoutDuration
        XCTAssertEqual(fields[11], "350.5")   // workoutTotalEnergyBurned
        XCTAssertEqual(fields[12], "5000.0")  // workoutTotalDistance
    }

    // MARK: - Mixed Types

    func testMixedTypesIncludesTypeColumn() throws {
        let samples = [
            makeSample(type: .stepCount, value: 5000, unit: "count"),
            makeSample(type: .heartRate, value: 72, unit: "count/min"),
            makeSample(type: .sleepAnalysis, value: nil, unit: nil, categoryValue: 1),
        ]
        let data = try formatter.format(samples: samples, options: ExportOptions())
        let lines = csvLines(from: data)

        let types = lines[1...].map { $0.components(separatedBy: ",")[1] }
        XCTAssertEqual(types, ["stepCount", "heartRate", "sleepAnalysis"])
    }

    // MARK: - CSV Escaping

    func testCommaInSourceNameIsEscaped() throws {
        let sample = makeSample(sourceName: "Apple Watch, Series 9")
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let raw = csvString(from: data)

        XCTAssertTrue(raw.contains("\"Apple Watch, Series 9\""), "Commas in fields should be quoted")
    }

    func testDoubleQuoteInValueIsEscaped() throws {
        let sample = makeSample(sourceName: "Test \"App\"")
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let raw = csvString(from: data)

        XCTAssertTrue(raw.contains("\"Test \"\"App\"\"\""), "Double quotes should be doubled and field quoted")
    }

    func testNewlineInMetadataIsEscaped() throws {
        let sample = makeSample(metadataJSON: "line1\nline2")
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let raw = csvString(from: data)

        XCTAssertTrue(raw.contains("\"line1\nline2\""), "Newlines in fields should be quoted")
    }

    // MARK: - Correlation Values

    func testCorrelationValuesFormatted() throws {
        let sample = makeSample(
            type: .bloodPressure,
            value: nil,
            unit: nil,
            correlationValues: ["systolic": 120, "diastolic": 80]
        )
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let raw = csvString(from: data)

        // Keys sorted: diastolic comes before systolic
        XCTAssertTrue(raw.contains("diastolic=80.0;systolic=120.0"), "Correlation values should be semicolon-separated key=value pairs")
    }

    // MARK: - ISO 8601 Dates

    func testDatesAreISO8601() throws {
        let sample = makeSample()
        let data = try formatter.format(samples: [sample], options: ExportOptions())
        let lines = csvLines(from: data)
        let fields = lines[1].components(separatedBy: ",")

        // startDate is field index 2
        XCTAssertTrue(fields[2].contains("T"), "Date should be ISO 8601 format")
    }

    // MARK: - Trailing Newline

    func testOutputEndsWithNewline() throws {
        let data = try formatter.format(samples: [makeSample()], options: ExportOptions())
        let raw = csvString(from: data)
        XCTAssertTrue(raw.hasSuffix("\n"), "CSV output should end with a newline")
    }
}
