import SwiftUI

// MARK: - Insight Card View

/// Card displaying a single auto-generated health insight.
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
        }
        .padding(12)
        .warmCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.dataType.displayName): \(insight.message)")
    }
}
