import SwiftUI

// MARK: - Insight Card View

/// Card displaying a single auto-generated health insight.
struct InsightCardView: View {

    // MARK: - Properties

    let insight: InsightItem

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(insight.dataType.category.chartColor)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.dataType.displayName)
                    .font(AppTypography.captionMedium)
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(AppTypography.subheadlineMedium)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .warmCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.dataType.displayName): \(message)")
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch insight {
        case .weeklySummary(_, let percentChange, _):
            return percentChange > 0 ? "arrow.up.right" : "arrow.down.right"
        case .personalRecord:
            return "trophy"
        case .dayOfWeekPattern:
            return "calendar"
        case .anomaly:
            return "exclamationmark.triangle"
        }
    }

    private var message: String {
        switch insight {
        case .weeklySummary(let type, let percentChange, let direction):
            let pct = Int(abs(percentChange))
            return "\(type.displayName) \(direction) \(pct)% vs last week"
        case .personalRecord(let type, _, _):
            return "New highest \(type.displayName.lowercased()) this month!"
        case .dayOfWeekPattern(_, let dayName):
            return "Most active on \(dayName)"
        case .anomaly(_, let metric, let direction):
            return "\(metric) \(direction) today"
        }
    }
}
