import XCTest
import HealthKit
@testable import HealthAppTransfer

final class AggregationEngineTests: XCTestCase {

    // MARK: - Type Validation

    func testAggregateRejectsCategoryType() async {
        let store = MockHealthStore()
        let engine = AggregationEngine(store: store)

        do {
            _ = try await engine.aggregate(
                type: .sleepAnalysis,
                operations: [.count],
                interval: .daily,
                from: Date(),
                to: Date()
            )
            XCTFail("Expected unsupportedType error")
        } catch let error as AggregationError {
            if case .unsupportedType(let type) = error {
                XCTAssertEqual(type, .sleepAnalysis)
            } else {
                XCTFail("Wrong error case")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testAggregateRejectsWorkoutType() async {
        let store = MockHealthStore()
        let engine = AggregationEngine(store: store)

        do {
            _ = try await engine.aggregate(
                type: .workout,
                operations: [.count],
                interval: .daily,
                from: Date(),
                to: Date()
            )
            XCTFail("Expected unsupportedType error")
        } catch is AggregationError {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testAggregateRejectsCharacteristicType() async {
        let store = MockHealthStore()
        let engine = AggregationEngine(store: store)

        do {
            _ = try await engine.aggregate(
                type: .biologicalSex,
                operations: [.count],
                interval: .daily,
                from: Date(),
                to: Date()
            )
            XCTFail("Expected unsupportedType error")
        } catch is AggregationError {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Statistics Options (Cumulative Types)

    func testStatisticsOptionsCumulativeSum() {
        let options = AggregationEngine.statisticsOptions(
            for: [.sum],
            isCumulative: true
        )
        XCTAssertTrue(options.contains(.cumulativeSum))
        XCTAssertFalse(options.contains(.discreteAverage))
    }

    func testStatisticsOptionsCumulativeIgnoresDiscreteOps() {
        let options = AggregationEngine.statisticsOptions(
            for: [.average, .min, .max],
            isCumulative: true
        )
        // Should skip all three and fallback to cumulativeSum
        XCTAssertTrue(options.contains(.cumulativeSum))
        XCTAssertFalse(options.contains(.discreteAverage))
        XCTAssertFalse(options.contains(.discreteMin))
        XCTAssertFalse(options.contains(.discreteMax))
    }

    // MARK: - Statistics Options (Discrete Types)

    func testStatisticsOptionsDiscreteAverage() {
        let options = AggregationEngine.statisticsOptions(
            for: [.average],
            isCumulative: false
        )
        XCTAssertTrue(options.contains(.discreteAverage))
        XCTAssertFalse(options.contains(.cumulativeSum))
    }

    func testStatisticsOptionsDiscreteMinMax() {
        let options = AggregationEngine.statisticsOptions(
            for: [.min, .max],
            isCumulative: false
        )
        XCTAssertTrue(options.contains(.discreteMin))
        XCTAssertTrue(options.contains(.discreteMax))
    }

    func testStatisticsOptionsDiscreteIgnoresCumulativeOps() {
        let options = AggregationEngine.statisticsOptions(
            for: [.sum],
            isCumulative: false
        )
        // Sum skipped for discrete, fallback to discreteAverage
        XCTAssertFalse(options.contains(.cumulativeSum))
        XCTAssertTrue(options.contains(.discreteAverage))
    }

    // MARK: - Statistics Options (Latest)

    func testStatisticsOptionsLatestWorksForBoth() {
        let cumOptions = AggregationEngine.statisticsOptions(
            for: [.latest],
            isCumulative: true
        )
        XCTAssertTrue(cumOptions.contains(.mostRecent))

        let discOptions = AggregationEngine.statisticsOptions(
            for: [.latest],
            isCumulative: false
        )
        XCTAssertTrue(discOptions.contains(.mostRecent))
    }

    // MARK: - Statistics Options (Count Fallback)

    func testStatisticsOptionsCountOnlyGetsFallback() {
        let cumOptions = AggregationEngine.statisticsOptions(
            for: [.count],
            isCumulative: true
        )
        XCTAssertTrue(cumOptions.contains(.cumulativeSum))

        let discOptions = AggregationEngine.statisticsOptions(
            for: [.count],
            isCumulative: false
        )
        XCTAssertTrue(discOptions.contains(.discreteAverage))
    }

    // MARK: - Statistics Options (Combined)

    func testStatisticsOptionsCombinedOperations() {
        let options = AggregationEngine.statisticsOptions(
            for: [.average, .min, .max, .latest],
            isCumulative: false
        )
        XCTAssertTrue(options.contains(.discreteAverage))
        XCTAssertTrue(options.contains(.discreteMin))
        XCTAssertTrue(options.contains(.discreteMax))
        XCTAssertTrue(options.contains(.mostRecent))
    }

    // MARK: - Anchor Date

    func testAnchorDateHourlyAlignedToStartOfDay() {
        let date = makeDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)
        let anchor = AggregationEngine.anchorDate(for: .hourly, relativeTo: date)
        let expected = makeDate(year: 2024, month: 6, day: 15, hour: 0, minute: 0)
        XCTAssertEqual(anchor, expected)
    }

    func testAnchorDateDailyAlignedToStartOfDay() {
        let date = makeDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)
        let anchor = AggregationEngine.anchorDate(for: .daily, relativeTo: date)
        let expected = makeDate(year: 2024, month: 6, day: 15, hour: 0, minute: 0)
        XCTAssertEqual(anchor, expected)
    }

    func testAnchorDateMonthlyAlignedToFirstOfMonth() {
        let date = makeDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)
        let anchor = AggregationEngine.anchorDate(for: .monthly, relativeTo: date)
        let expected = makeDate(year: 2024, month: 6, day: 1, hour: 0, minute: 0)
        XCTAssertEqual(anchor, expected)
    }

    func testAnchorDateYearlyAlignedToJanuary() {
        let date = makeDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)
        let anchor = AggregationEngine.anchorDate(for: .yearly, relativeTo: date)
        let expected = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        XCTAssertEqual(anchor, expected)
    }

    // MARK: - Aggregation Results

    func testAggregateReturnsMockResults() async throws {
        let store = MockHealthStore()
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        store.aggregatedStatisticsResults = [
            AggregatedSample(
                startDate: yesterday,
                endDate: now,
                sum: 10000,
                average: nil,
                min: nil,
                max: nil,
                latest: 500,
                count: 1,
                unit: "count"
            )
        ]

        let engine = AggregationEngine(store: store)
        let results = try await engine.aggregate(
            type: .stepCount,
            operations: [.sum, .latest],
            interval: .daily,
            from: yesterday,
            to: now
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].sum, 10000)
        XCTAssertEqual(results[0].latest, 500)
        XCTAssertEqual(results[0].count, 1)
        XCTAssertEqual(results[0].unit, "count")
    }

    func testAggregateReturnsMultipleIntervals() async throws {
        let store = MockHealthStore()
        let now = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        store.aggregatedStatisticsResults = [
            AggregatedSample(
                startDate: twoDaysAgo, endDate: oneDayAgo,
                sum: 8000, average: nil, min: nil, max: nil, latest: nil,
                count: 1, unit: "count"
            ),
            AggregatedSample(
                startDate: oneDayAgo, endDate: now,
                sum: 12000, average: nil, min: nil, max: nil, latest: nil,
                count: 1, unit: "count"
            )
        ]

        let engine = AggregationEngine(store: store)
        let results = try await engine.aggregate(
            type: .stepCount,
            operations: [.sum],
            interval: .daily,
            from: twoDaysAgo,
            to: now
        )

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].sum, 8000)
        XCTAssertEqual(results[1].sum, 12000)
    }

    func testAggregateReturnsEmptyForNoData() async throws {
        let store = MockHealthStore()
        store.aggregatedStatisticsResults = []

        let engine = AggregationEngine(store: store)
        let results = try await engine.aggregate(
            type: .heartRate,
            operations: [.average],
            interval: .hourly,
            from: Date(),
            to: Date()
        )

        XCTAssertTrue(results.isEmpty)
    }

    func testAggregateDiscreteTypeReturnsStats() async throws {
        let store = MockHealthStore()
        let now = Date()
        let hourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: now)!

        store.aggregatedStatisticsResults = [
            AggregatedSample(
                startDate: hourAgo, endDate: now,
                sum: nil, average: 72.5, min: 58.0, max: 95.0, latest: 68.0,
                count: 1, unit: "count/min"
            )
        ]

        let engine = AggregationEngine(store: store)
        let results = try await engine.aggregate(
            type: .heartRate,
            operations: [.average, .min, .max, .latest],
            interval: .hourly,
            from: hourAgo,
            to: now
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results[0].sum)
        XCTAssertEqual(results[0].average, 72.5)
        XCTAssertEqual(results[0].min, 58.0)
        XCTAssertEqual(results[0].max, 95.0)
        XCTAssertEqual(results[0].latest, 68.0)
    }

    // MARK: - Error Propagation

    func testAggregatePropagatesStoreErrors() async {
        let store = MockHealthStore()
        store.aggregatedStatisticsError = NSError(domain: "test", code: 99)

        let engine = AggregationEngine(store: store)

        do {
            _ = try await engine.aggregate(
                type: .stepCount,
                operations: [.sum],
                interval: .daily,
                from: Date(),
                to: Date()
            )
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual((error as NSError).code, 99)
        }
    }

    // MARK: - Interval DateComponents

    func testIntervalDateComponents() {
        XCTAssertEqual(AggregationInterval.hourly.dateComponents, DateComponents(hour: 1))
        XCTAssertEqual(AggregationInterval.daily.dateComponents, DateComponents(day: 1))
        XCTAssertEqual(AggregationInterval.weekly.dateComponents, DateComponents(day: 7))
        XCTAssertEqual(AggregationInterval.monthly.dateComponents, DateComponents(month: 1))
        XCTAssertEqual(AggregationInterval.yearly.dateComponents, DateComponents(year: 1))
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components)!
    }
}
