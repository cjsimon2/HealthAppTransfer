import XCTest
@testable import HealthAppTransfer

final class WidgetDataStoreTests: XCTestCase {

    // MARK: - Properties

    private var sut: WidgetDataStore!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        sut = WidgetDataStore(suiteName: "test.widgets.\(UUID().uuidString)")
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeSnapshot(
        metricType: String = "stepCount",
        displayName: String = "Step Count",
        value: Double? = 5000
    ) -> WidgetMetricSnapshot {
        WidgetMetricSnapshot(
            metricType: metricType,
            displayName: displayName,
            iconName: "figure.walk",
            currentValue: value,
            unit: "steps",
            sparklineValues: [1000, 2000, 3000, 4000, 5000, 6000, 7000],
            lastUpdated: Date()
        )
    }

    // MARK: - Save & Load

    func testSaveAndLoadAllRoundtrip() {
        let snapshots = [
            makeSnapshot(metricType: "stepCount", displayName: "Step Count", value: 5000),
            makeSnapshot(metricType: "heartRate", displayName: "Heart Rate", value: 72)
        ]

        sut.save(snapshots)
        let loaded = sut.loadAll()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].metricType, "stepCount")
        XCTAssertEqual(loaded[0].currentValue, 5000)
        XCTAssertEqual(loaded[1].metricType, "heartRate")
        XCTAssertEqual(loaded[1].currentValue, 72)
    }

    // MARK: - Snapshot by Type

    func testSnapshotForTypeReturnsMatchingSnapshot() {
        let snapshots = [
            makeSnapshot(metricType: "stepCount"),
            makeSnapshot(metricType: "heartRate")
        ]
        sut.save(snapshots)

        let result = sut.snapshot(for: "heartRate")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.metricType, "heartRate")
    }

    func testSnapshotForTypeReturnsNilForUnknownType() {
        let snapshots = [makeSnapshot(metricType: "stepCount")]
        sut.save(snapshots)

        let result = sut.snapshot(for: "bloodGlucose")
        XCTAssertNil(result)
    }

    // MARK: - Empty State

    func testLoadAllReturnsEmptyArrayWhenNothingSaved() {
        let loaded = sut.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }
}
