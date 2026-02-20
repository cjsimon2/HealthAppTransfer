import SwiftUI
import Charts
import Accessibility

// MARK: - Health Chart View

struct HealthChartView: View {

    // MARK: - Observed Objects

    @StateObject private var viewModel: ChartViewModel

    // MARK: - State

    @State private var selectedDate: Date?

    // MARK: - Init

    init(dataType: HealthDataType, aggregationEngine: AggregationEngine) {
        _viewModel = StateObject(wrappedValue: ChartViewModel(
            dataType: dataType,
            aggregationEngine: aggregationEngine
        ))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            dateRangePicker

            if viewModel.selectedRange == .custom {
                customDateRange
            }

            chartTypeSelector
            chartArea
        }
        .padding(.horizontal, 16)
        .task { await viewModel.loadData() }
        .onChange(of: viewModel.selectedRange) {
            guard viewModel.selectedRange != .custom else { return }
            Task { await viewModel.loadData() }
        }
    }

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        Picker("Date Range", selection: $viewModel.selectedRange) {
            ForEach(ChartDateRange.allCases) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Chart date range")
    }

    // MARK: - Custom Date Range

    private var customDateRange: some View {
        HStack(spacing: 12) {
            DatePicker(
                "From",
                selection: $viewModel.customStartDate,
                in: ...viewModel.customEndDate,
                displayedComponents: .date
            )
            .labelsHidden()

            Text("to")
                .foregroundStyle(.secondary)

            DatePicker(
                "To",
                selection: $viewModel.customEndDate,
                in: viewModel.customStartDate...,
                displayedComponents: .date
            )
            .labelsHidden()

            Button("Apply") {
                Task { await viewModel.loadData() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Custom date range")
    }

    // MARK: - Chart Type Selector

    private var chartTypeSelector: some View {
        Picker("Chart Type", selection: $viewModel.markType) {
            ForEach(ChartMarkType.allCases) { type in
                Label(type.rawValue, systemImage: type.iconName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Chart display type")
    }

    // MARK: - Chart Area

    @ViewBuilder
    private var chartArea: some View {
        if viewModel.isLoading {
            ProgressView("Loading chart data…")
                .frame(height: 240)
        } else if let error = viewModel.error {
            errorView(error)
        } else if viewModel.isEmpty {
            emptyState
        } else {
            VStack(spacing: 8) {
                chartContent
                    .frame(height: 240)

                if let sample = viewModel.selectedSample {
                    tooltipView(sample)
                }
            }
        }
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        Chart(viewModel.activeSamples, id: \.startDate) { sample in
            let value = viewModel.chartValue(for: sample)
            let name = viewModel.dataType.displayName

            switch viewModel.markType {
            case .line:
                LineMark(
                    x: .value("Date", sample.startDate),
                    y: .value(name, value)
                )
                .interpolationMethod(.catmullRom)

            case .bar:
                BarMark(
                    x: .value("Date", sample.startDate),
                    y: .value(name, value)
                )

            case .area:
                AreaMark(
                    x: .value("Date", sample.startDate),
                    y: .value(name, value)
                )
                .interpolationMethod(.catmullRom)
                .opacity(0.3)

                LineMark(
                    x: .value("Date", sample.startDate),
                    y: .value(name, value)
                )
                .interpolationMethod(.catmullRom)
            }

            if viewModel.markType == .line,
               viewModel.selectedSample?.startDate == sample.startDate {
                PointMark(
                    x: .value("Date", sample.startDate),
                    y: .value(name, value)
                )
                .symbolSize(60)
            }
        }
        .healthChartStyle(for: viewModel.dataType.category)
        .chartYAxisLabel(viewModel.displayUnit)
        .chartScrollableAxes(.horizontal)
        .chartXSelection(value: $selectedDate)
        .onChange(of: selectedDate) { _, newDate in
            if let newDate {
                viewModel.selectedSample = viewModel.sample(nearestTo: newDate)
            } else {
                viewModel.selectedSample = nil
            }
        }
        .accessibilityChartDescriptor(HealthChartDescriptor(
            dataType: viewModel.dataType,
            samples: viewModel.activeSamples,
            unit: viewModel.displayUnit,
            rangeName: viewModel.selectedRange.label,
            isContinuous: viewModel.markType != .bar
        ))
    }

    // MARK: - Tooltip

    private func tooltipView(_ sample: AggregatedSample) -> some View {
        let value = viewModel.chartValue(for: sample)

        return VStack(spacing: 4) {
            Text(sample.startDate, format: tooltipDateFormat)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(value, specifier: "%.1f") \(viewModel.displayUnit)")
                .font(.headline)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(viewModel.dataType.displayName): \(String(format: "%.1f", value)) \(viewModel.displayUnit)"
        )
    }

    private var tooltipDateFormat: Date.FormatStyle {
        switch viewModel.selectedRange {
        case .day:
            return .dateTime.hour().minute()
        case .week, .month, .custom:
            return .dateTime.month(.abbreviated).day()
        case .year:
            return .dateTime.year().month(.abbreviated)
        }
    }

    // MARK: - Empty & Error States

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Data")
                .font(.title3.bold())

            Text("No \(viewModel.dataType.displayName) data for this date range.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 240)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text("Chart Error")
                .font(.title3.bold())

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 240)
    }
}

// MARK: - Accessibility Chart Descriptor

struct HealthChartDescriptor: AXChartDescriptorRepresentable {
    let dataType: HealthDataType
    let samples: [AggregatedSample]
    let unit: String
    let rangeName: String
    let isContinuous: Bool

    func makeChartDescriptor() -> AXChartDescriptor {
        guard let firstSample = samples.first, let lastSample = samples.last else {
            return emptyDescriptor
        }

        let minX = firstSample.startDate.timeIntervalSince1970
        let maxX = lastSample.startDate.timeIntervalSince1970
        let xRange = minX == maxX ? minX...(maxX + 3600) : minX...maxX

        let xAxis = AXNumericDataAxisDescriptor(
            title: "Date",
            range: xRange,
            gridlinePositions: []
        ) { value in
            Date(timeIntervalSince1970: value).formatted(date: .abbreviated, time: .shortened)
        }

        let values = samples.map { chartValue(for: $0) }
        let minY = values.min() ?? 0
        let maxY = values.max() ?? 0
        let yRange = minY == maxY ? minY...(maxY + 1) : minY...maxY

        let yAxis = AXNumericDataAxisDescriptor(
            title: "\(dataType.displayName) (\(unit))",
            range: yRange,
            gridlinePositions: []
        ) { value in
            "\(String(format: "%.1f", value)) \(unit)"
        }

        let dataPoints = samples.map { sample in
            AXDataPoint(
                x: sample.startDate.timeIntervalSince1970,
                y: chartValue(for: sample)
            )
        }

        let series = AXDataSeriesDescriptor(
            name: dataType.displayName,
            isContinuous: isContinuous,
            dataPoints: dataPoints
        )

        return AXChartDescriptor(
            title: "\(dataType.displayName) — \(rangeName)",
            summary: "\(samples.count) data points",
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }

    // MARK: - Private

    private func chartValue(for sample: AggregatedSample) -> Double {
        sample.sum ?? sample.average ?? sample.latest ?? 0
    }

    private var emptyDescriptor: AXChartDescriptor {
        AXChartDescriptor(
            title: dataType.displayName,
            summary: "No data",
            xAxis: AXNumericDataAxisDescriptor(
                title: "Date", range: 0...1, gridlinePositions: []
            ) { _ in "" },
            yAxis: AXNumericDataAxisDescriptor(
                title: "Value", range: 0...1, gridlinePositions: []
            ) { _ in "" },
            series: []
        )
    }
}
