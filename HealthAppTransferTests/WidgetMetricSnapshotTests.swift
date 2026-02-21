import XCTest
@testable import HealthAppTransfer

final class WidgetMetricSnapshotTests: XCTestCase {

    // MARK: - Helpers

    private func makeSnapshot(
        metricType: String = "stepCount",
        displayName: String = "Step Count",
        iconName: String = "flame.fill",
        currentValue: Double? = 8500,
        unit: String = "steps",
        sparklineValues: [Double] = [7000, 8000, 9000, 8500, 7500, 10000, 8500],
        lastUpdated: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> WidgetMetricSnapshot {
        WidgetMetricSnapshot(
            metricType: metricType,
            displayName: displayName,
            iconName: iconName,
            currentValue: currentValue,
            unit: unit,
            sparklineValues: sparklineValues,
            lastUpdated: lastUpdated
        )
    }

    // MARK: - Codable Roundtrip

    func testCodableRoundtrip() throws {
        let snapshot = makeSnapshot()
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetMetricSnapshot.self, from: data)

        XCTAssertEqual(decoded.metricType, snapshot.metricType)
        XCTAssertEqual(decoded.displayName, snapshot.displayName)
        XCTAssertEqual(decoded.iconName, snapshot.iconName)
        XCTAssertEqual(decoded.currentValue, snapshot.currentValue)
        XCTAssertEqual(decoded.unit, snapshot.unit)
        XCTAssertEqual(decoded.sparklineValues, snapshot.sparklineValues)
        XCTAssertEqual(decoded.lastUpdated, snapshot.lastUpdated)
    }

    // MARK: - ID Equals MetricType

    func testIdEqualsMetricType() {
        let snapshot = makeSnapshot(metricType: "heartRate")
        XCTAssertEqual(snapshot.id, "heartRate")
        XCTAssertEqual(snapshot.id, snapshot.metricType)
    }
}
