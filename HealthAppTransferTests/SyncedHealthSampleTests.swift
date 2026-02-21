import XCTest
import SwiftData
@testable import HealthAppTransfer

@MainActor
final class SyncedHealthSampleTests: XCTestCase {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(
            for: SyncedHealthSample.self,
            configurations: config
        )
    }

    private func makeSampleDTO(
        id: UUID = UUID(),
        type: HealthDataType = .stepCount,
        value: Double? = 1234,
        unit: String? = "count",
        correlationValues: [String: Double]? = nil,
        characteristicValue: String? = nil
    ) -> HealthSampleDTO {
        HealthSampleDTO(
            id: id,
            type: type,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_003_600),
            sourceName: "TestSource",
            sourceBundleIdentifier: "com.test.app",
            value: value,
            unit: unit,
            categoryValue: nil,
            workoutActivityType: nil,
            workoutDuration: nil,
            workoutTotalEnergyBurned: nil,
            workoutTotalDistance: nil,
            correlationValues: correlationValues,
            characteristicValue: characteristicValue,
            metadataJSON: nil
        )
    }

    // MARK: - DTO to Model to DTO Roundtrip

    func testDTOToModelRoundtrip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let originalDTO = makeSampleDTO()
        let sample = SyncedHealthSample(from: originalDTO, syncSource: "lan")
        context.insert(sample)

        let roundtripped = sample.toDTO()

        XCTAssertEqual(roundtripped.id, originalDTO.id)
        XCTAssertEqual(roundtripped.type, originalDTO.type)
        XCTAssertEqual(roundtripped.startDate, originalDTO.startDate)
        XCTAssertEqual(roundtripped.endDate, originalDTO.endDate)
        XCTAssertEqual(roundtripped.sourceName, originalDTO.sourceName)
        XCTAssertEqual(roundtripped.sourceBundleIdentifier, originalDTO.sourceBundleIdentifier)
        XCTAssertEqual(roundtripped.value, originalDTO.value)
        XCTAssertEqual(roundtripped.unit, originalDTO.unit)
    }

    func testSyncSourceIsPreserved() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let dto = makeSampleDTO()
        let sample = SyncedHealthSample(from: dto, syncSource: "cloudkit")
        context.insert(sample)

        XCTAssertEqual(sample.syncSource, "cloudkit")
    }

    // MARK: - Correlation Values Roundtrip

    func testCorrelationValuesRoundtrip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let correlations = ["systolic": 120.0, "diastolic": 80.0]
        let dto = makeSampleDTO(
            type: .bloodPressure,
            value: nil,
            unit: nil,
            correlationValues: correlations
        )
        let sample = SyncedHealthSample(from: dto, syncSource: "lan")
        context.insert(sample)

        XCTAssertNotNil(sample.correlationValuesJSON)

        let roundtripped = sample.toDTO()
        XCTAssertEqual(roundtripped.correlationValues?["systolic"], 120.0)
        XCTAssertEqual(roundtripped.correlationValues?["diastolic"], 80.0)
    }

    func testNilCorrelationValuesProducesNilJSON() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let dto = makeSampleDTO(correlationValues: nil)
        let sample = SyncedHealthSample(from: dto, syncSource: "lan")
        context.insert(sample)

        XCTAssertNil(sample.correlationValuesJSON)

        let roundtripped = sample.toDTO()
        XCTAssertNil(roundtripped.correlationValues)
    }
}
