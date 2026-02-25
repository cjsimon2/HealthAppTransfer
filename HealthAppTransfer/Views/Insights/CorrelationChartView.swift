import SwiftUI
import Charts

// MARK: - Correlation Chart View

/// Scatter plot showing the correlation between two health metrics.
struct CorrelationChartView: View {

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: - Properties

    let result: CorrelationResult

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            rValueHeader
            scatterChart
        }
        .padding(12)
        .warmCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    private var rValueHeader: some View {
        HStack(spacing: 8) {
            Text("r = \(result.rValue, specifier: "%.2f")")
                .font(AppTypography.monoValueSmall)

            Text(result.strengthLabel)
                .font(AppTypography.captionMedium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(strengthColor.opacity(0.12), in: Capsule())
        }
    }

    @ViewBuilder
    private var scatterChart: some View {
        let dataPoints = result.points.map {
            CorrelationDataPoint(x: $0.x, y: $0.y, date: $0.date)
        }

        if dataPoints.isEmpty {
            emptyState
        } else {
            Chart(dataPoints) { point in
                PointMark(
                    x: .value(result.typeA.displayName, point.x),
                    y: .value(result.typeB.displayName, point.y)
                )
                .symbolSize(40)
                .foregroundStyle(result.typeA.category.chartColor)
            }
            .chartXAxisLabel(result.typeA.displayName)
            .chartYAxisLabel(result.typeB.displayName)
            .frame(height: sizeClass == .regular ? 280 : 240)
            .accessibilityHidden(true)
        }
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.06))
            .frame(height: sizeClass == .regular ? 280 : 240)
            .overlay {
                Text("Not enough matching data points")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Helpers

    private var strengthColor: Color {
        switch result.strengthLabel {
        case "Strong": return AppColors.secondary
        case "Moderate": return AppColors.primary
        default: return .secondary
        }
    }

    private var accessibilityDescription: String {
        "\(result.typeA.displayName) vs \(result.typeB.displayName): " +
        "correlation \(result.rValue >= 0 ? "positive" : "negative"), " +
        "\(result.strengthLabel.lowercased()), " +
        "r equals \(String(format: "%.2f", result.rValue)), " +
        "\(result.points.count) data points"
    }
}
