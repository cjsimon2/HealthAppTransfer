import SwiftUI
import Charts

// MARK: - Metric Card View

/// Dashboard card showing a health metric's icon, name, latest value, and 7-day sparkline.
struct MetricCardView: View {

    // MARK: - Properties

    let dataType: HealthDataType
    let latestValue: String
    let samples: [AggregatedSample]
    let trendDirection: TrendDirection

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            latestValueLabel
            sparklineChart
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(spacing: 6) {
            Image(systemName: dataType.category.iconName)
                .font(.subheadline)
                .foregroundStyle(dataType.category.chartColor)

            Text(dataType.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var latestValueLabel: some View {
        HStack(spacing: 4) {
            Text(latestValue)
                .font(.title3.bold().monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            trendIndicator
        }
    }

    @ViewBuilder
    private var trendIndicator: some View {
        switch trendDirection {
        case .up:
            Image(systemName: "arrow.up.right")
                .font(.caption2.bold())
                .foregroundStyle(.green)
        case .down:
            Image(systemName: "arrow.down.right")
                .font(.caption2.bold())
                .foregroundStyle(.red)
        case .flat:
            Image(systemName: "arrow.right")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        case .noData:
            EmptyView()
        }
    }

    @ViewBuilder
    private var sparklineChart: some View {
        let activeSamples = samples.filter { $0.count > 0 }
        if activeSamples.count >= 2 {
            Chart(activeSamples, id: \.startDate) { sample in
                LineMark(
                    x: .value("Date", sample.startDate),
                    y: .value("Value", chartValue(for: sample))
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .foregroundStyle(dataType.category.chartColor.gradient)
            .frame(height: 40)
            .accessibilityHidden(true)
        } else {
            Rectangle()
                .fill(.clear)
                .frame(height: 40)
                .overlay {
                    Text("No trend data")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .accessibilityHidden(true)
        }
    }

    // MARK: - Helpers

    private func chartValue(for sample: AggregatedSample) -> Double {
        sample.sum ?? sample.average ?? sample.latest ?? 0
    }

    private var accessibilityDescription: String {
        let trend: String
        switch trendDirection {
        case .up: trend = ", trending up"
        case .down: trend = ", trending down"
        case .flat: trend = ", stable"
        case .noData: trend = ""
        }
        return "\(dataType.displayName): \(latestValue)\(trend)"
    }
}

// MARK: - Trend Direction

enum TrendDirection: Sendable {
    case up
    case down
    case flat
    case noData
}
