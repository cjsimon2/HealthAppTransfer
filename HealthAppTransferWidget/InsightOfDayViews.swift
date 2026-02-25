import SwiftUI
import WidgetKit

// MARK: - Entry View

/// Routes to the appropriate layout based on widget family.
struct InsightOfDayEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: InsightEntry

    var body: some View {
        if let insight = entry.insight {
            switch family {
            case .systemMedium:
                MediumInsightView(insight: insight)
            default:
                SmallInsightView(insight: insight)
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "lightbulb")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No insights yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Small Widget

/// Compact layout: icon + message.
struct SmallInsightView: View {
    let insight: WidgetInsightSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: insight.categoryIconName)
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text(insight.metricName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: insight.iconName)
                .font(.title2)
                .foregroundStyle(.orange)

            Text(insight.message)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.metricName): \(insight.message)")
    }
}

// MARK: - Medium Widget

/// Wider layout: icon + metric name + message + relative timestamp.
struct MediumInsightView: View {
    let insight: WidgetInsightSnapshot

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.iconName)
                .font(.largeTitle)
                .foregroundStyle(.orange)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: insight.categoryIconName)
                        .foregroundStyle(.blue)
                        .font(.caption2)
                    Text(insight.metricName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(insight.message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(insight.lastUpdated, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.metricName): \(insight.message)")
    }
}
