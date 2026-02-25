import SwiftUI
import Charts

// MARK: - Insight Card View

/// Card displaying a single auto-generated health insight with optional sparkline.
struct InsightCardView: View {

    // MARK: - Properties

    let insight: InsightItem

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.iconName)
                .font(.title3)
                .foregroundStyle(insight.dataType.category.chartColor)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.dataType.displayName)
                    .font(AppTypography.captionMedium)
                    .foregroundStyle(.secondary)

                Text(insight.message)
                    .font(AppTypography.subheadlineMedium)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let data = insight.sparkline, data.count >= 2 {
                sparklineChart(data: data)
            }
        }
        .padding(12)
        .warmCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.dataType.displayName): \(insight.message)")
    }

    // MARK: - Sparkline

    @ViewBuilder
    private func sparklineChart(data: [Double]) -> some View {
        Chart(Array(data.enumerated()), id: \.offset) { index, value in
            AreaMark(
                x: .value("Day", index),
                y: .value("Value", value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(insight.dataType.category.chartColor.opacity(0.12).gradient)

            LineMark(
                x: .value("Day", index),
                y: .value("Value", value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(insight.dataType.category.chartColor.gradient)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(width: 64, height: 32)
        .accessibilityHidden(true)
    }
}
