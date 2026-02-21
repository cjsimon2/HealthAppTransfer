import XCTest
@testable import HealthAppTransfer

@MainActor
final class ChartViewModelTests: XCTestCase {

    // MARK: - ChartDateRange Label

    func testChartDateRangeLabels() {
        XCTAssertEqual(ChartDateRange.day.label, "D")
        XCTAssertEqual(ChartDateRange.week.label, "W")
        XCTAssertEqual(ChartDateRange.month.label, "M")
        XCTAssertEqual(ChartDateRange.year.label, "Y")
        XCTAssertEqual(ChartDateRange.custom.label, "…")
    }

    // MARK: - ChartDateRange Interval

    func testChartDateRangeIntervalMapping() {
        XCTAssertEqual(ChartDateRange.day.interval, .hourly)
        XCTAssertEqual(ChartDateRange.week.interval, .daily)
        XCTAssertEqual(ChartDateRange.month.interval, .daily)
        XCTAssertEqual(ChartDateRange.year.interval, .monthly)
        XCTAssertEqual(ChartDateRange.custom.interval, .daily)
    }

    // MARK: - ChartDateRange Default Date Range

    func testDefaultDateRangeReturnsValidRangeForEachCase() {
        for range in ChartDateRange.allCases {
            let dateRange = range.defaultDateRange
            XCTAssertTrue(dateRange.start < dateRange.end,
                          "\(range.rawValue) should have start < end")
        }
    }

    // MARK: - ChartMarkType Display

    func testChartMarkTypeDisplayNames() {
        XCTAssertEqual(ChartMarkType.line.displayName, "Line")
        XCTAssertEqual(ChartMarkType.bar.displayName, "Bar")
        XCTAssertEqual(ChartMarkType.area.displayName, "Area")
    }

    func testChartMarkTypeIconNames() {
        XCTAssertEqual(ChartMarkType.line.iconName, "chart.xyaxis.line")
        XCTAssertEqual(ChartMarkType.bar.iconName, "chart.bar.fill")
        XCTAssertEqual(ChartMarkType.area.iconName, "chart.line.uptrend.xyaxis")
    }

    // MARK: - Init

    func testInitSetsDataTypeAndDefaultRange() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        XCTAssertEqual(vm.dataType, .stepCount)
        XCTAssertEqual(vm.selectedRange, .week)
    }

    // MARK: - Display Unit

    func testDisplayUnitIsEmptyWhenNoSamples() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        XCTAssertEqual(vm.displayUnit, "")
    }

    func testDisplayUnitReturnsUnitWhenSamplesExist() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.samples = [makeSample(sum: 100, count: 1, unit: "count")]
        XCTAssertEqual(vm.displayUnit, "count")
    }

    // MARK: - isEmpty

    func testIsEmptyWhenAllSamplesHaveZeroCount() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.samples = [
            makeSample(sum: 100, count: 0, unit: "count"),
            makeSample(sum: 200, count: 0, unit: "count")
        ]
        XCTAssertTrue(vm.isEmpty)
    }

    func testIsNotEmptyWhenAnySampleHasPositiveCount() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.samples = [
            makeSample(sum: 100, count: 0, unit: "count"),
            makeSample(sum: 200, count: 1, unit: "count")
        ]
        XCTAssertFalse(vm.isEmpty)
    }

    // MARK: - Active Samples

    func testActiveSamplesFiltersOutZeroCount() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.samples = [
            makeSample(sum: 100, count: 1, unit: "count"),
            makeSample(sum: 0, count: 0, unit: "count"),
            makeSample(sum: 200, count: 1, unit: "count")
        ]
        XCTAssertEqual(vm.activeSamples.count, 2)
    }

    // MARK: - Start/End Date

    func testStartEndDateUseSelectedRangeByDefault() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.selectedRange = .week
        let expected = ChartDateRange.week.defaultDateRange
        // Dates should be very close (within a second) since defaultDateRange uses Date()
        XCTAssertEqual(vm.startDate.timeIntervalSince1970, expected.start.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(vm.endDate.timeIntervalSince1970, expected.end.timeIntervalSince1970, accuracy: 1.0)
    }

    func testStartEndDateUseCustomDatesWhenCustomRange() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        let customStart = Date(timeIntervalSince1970: 1_000_000)
        let customEnd = Date(timeIntervalSince1970: 2_000_000)
        vm.selectedRange = .custom
        vm.customStartDate = customStart
        vm.customEndDate = customEnd
        XCTAssertEqual(vm.startDate, customStart)
        XCTAssertEqual(vm.endDate, customEnd)
    }

    // MARK: - Interval for Custom Range

    func testIntervalReturnsSelectedRangeIntervalNormally() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.selectedRange = .day
        XCTAssertEqual(vm.interval, .hourly)
    }

    func testIntervalAutoSelectsHourlyForCustomUnder1Day() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.selectedRange = .custom
        vm.customStartDate = Date()
        vm.customEndDate = Date().addingTimeInterval(3600) // 1 hour
        XCTAssertEqual(vm.interval, .hourly)
    }

    func testIntervalAutoSelectsDailyForCustomUnder90Days() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.selectedRange = .custom
        let now = Date()
        vm.customStartDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        vm.customEndDate = now
        XCTAssertEqual(vm.interval, .daily)
    }

    func testIntervalAutoSelectsWeeklyForCustomUnder365Days() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.selectedRange = .custom
        let now = Date()
        vm.customStartDate = Calendar.current.date(byAdding: .day, value: -200, to: now)!
        vm.customEndDate = now
        XCTAssertEqual(vm.interval, .weekly)
    }

    func testIntervalAutoSelectsMonthlyForCustomOver365Days() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.selectedRange = .custom
        let now = Date()
        vm.customStartDate = Calendar.current.date(byAdding: .day, value: -400, to: now)!
        vm.customEndDate = now
        XCTAssertEqual(vm.interval, .monthly)
    }

    // MARK: - Chart Value

    func testChartValueReturnsSumFirst() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        let sample = makeSample(sum: 500, average: 100, latest: 50, count: 1, unit: "count")
        XCTAssertEqual(vm.chartValue(for: sample), 500)
    }

    func testChartValueReturnsAverageWhenNoSum() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        let sample = makeSample(sum: nil, average: 72, latest: 50, count: 1, unit: "bpm")
        XCTAssertEqual(vm.chartValue(for: sample), 72)
    }

    func testChartValueReturnsLatestWhenNoSumOrAverage() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        let sample = makeSample(sum: nil, average: nil, latest: 98.6, count: 1, unit: "F")
        XCTAssertEqual(vm.chartValue(for: sample), 98.6)
    }

    func testChartValueReturnsZeroWhenAllNil() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        let sample = makeSample(sum: nil, average: nil, latest: nil, count: 1, unit: "")
        XCTAssertEqual(vm.chartValue(for: sample), 0)
    }

    // MARK: - Sample Nearest To

    func testSampleNearestToFindsClosestActiveSample() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        let now = Date()
        let sample1 = makeSample(startDate: now.addingTimeInterval(-3600), sum: 100, count: 1, unit: "count")
        let sample2 = makeSample(startDate: now.addingTimeInterval(-60), sum: 200, count: 1, unit: "count")
        let sample3 = makeSample(startDate: now.addingTimeInterval(-7200), sum: 300, count: 1, unit: "count")
        vm.samples = [sample1, sample2, sample3]

        let nearest = vm.sample(nearestTo: now)
        XCTAssertEqual(nearest?.sum, 200)
    }

    func testSampleNearestToSkipsInactiveSamples() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        let now = Date()
        let inactive = makeSample(startDate: now, sum: 999, count: 0, unit: "count")
        let active = makeSample(startDate: now.addingTimeInterval(-3600), sum: 100, count: 1, unit: "count")
        vm.samples = [inactive, active]

        let nearest = vm.sample(nearestTo: now)
        XCTAssertEqual(nearest?.sum, 100)
    }

    func testSampleNearestToReturnsNilWhenNoActiveSamples() {
        let vm = ChartViewModel(dataType: .stepCount, aggregationEngine: AggregationEngine())
        vm.samples = [makeSample(sum: 0, count: 0, unit: "count")]
        XCTAssertNil(vm.sample(nearestTo: Date()))
    }

    // MARK: - Helpers

    private func makeSample(
        startDate: Date = Date(),
        sum: Double? = nil,
        average: Double? = nil,
        latest: Double? = nil,
        count: Int = 1,
        unit: String = "count"
    ) -> AggregatedSample {
        AggregatedSample(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(3600),
            sum: sum,
            average: average,
            min: nil,
            max: nil,
            latest: latest,
            count: count,
            unit: unit
        )
    }
}
