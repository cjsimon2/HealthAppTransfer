import SwiftUI
import WidgetKit

// MARK: - Entry View

/// Routes to the appropriate view based on widget family.
struct HealthWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HealthMetricEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallMetricView(metric: entry.metrics.first ?? Self.fallbackMetric)
            case .systemMedium:
                MediumMetricView(metrics: entry.metrics)
            case .systemLarge:
                LargeMetricView(metrics: entry.metrics)
            default:
                SmallMetricView(metric: entry.metrics.first ?? Self.fallbackMetric)
            }
        }
    }

    private static let fallbackMetric = HealthMetricProvider.placeholderMetrics(for: .systemSmall)[0]
}

// MARK: - Small Widget

/// Single metric with current value and sparkline.
struct SmallMetricView: View {
    let metric: WidgetMetricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: metric.iconName)
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text(metric.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            SparklineView(values: metric.sparklineValues)
                .frame(height: 30)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedValue(metric.currentValue))
                    .font(.title.bold())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(metric.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.displayName): \(formattedValue(metric.currentValue)) \(metric.unit)")
    }
}

// MARK: - Medium Widget

/// Shows 2-3 metrics in a horizontal layout with sparklines.
struct MediumMetricView: View {
    let metrics: [WidgetMetricSnapshot]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(metrics.prefix(3).enumerated()), id: \.element.id) { index, metric in
                if index > 0 {
                    Divider()
                        .padding(.vertical, 8)
                }
                CompactMetricCell(metric: metric)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
}

// MARK: - Large Widget

/// Mini dashboard showing 4-6 metrics in a grid layout.
struct LargeMetricView: View {
    let metrics: [WidgetMetricSnapshot]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "heart.text.clipboard")
                    .foregroundStyle(.blue)
                Text("Health Dashboard")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(metrics.prefix(6)) { metric in
                    DashboardMetricCell(metric: metric)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Compact Metric Cell

/// Cell for medium widget — icon, name, sparkline, value.
private struct CompactMetricCell: View {
    let metric: WidgetMetricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: metric.iconName)
                    .foregroundStyle(.blue)
                    .font(.caption2)
                Text(metric.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            SparklineView(values: metric.sparklineValues)
                .frame(height: 24)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formattedValue(metric.currentValue))
                    .font(.title3.bold())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(metric.unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.displayName): \(formattedValue(metric.currentValue)) \(metric.unit)")
    }
}

// MARK: - Dashboard Metric Cell

/// Cell for large widget — compact card with sparkline.
private struct DashboardMetricCell: View {
    let metric: WidgetMetricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: metric.iconName)
                    .foregroundStyle(.blue)
                    .font(.caption2)
                Text(metric.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            SparklineView(values: metric.sparklineValues)
                .frame(height: 20)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formattedValue(metric.currentValue))
                    .font(.callout.bold())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(metric.unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.displayName): \(formattedValue(metric.currentValue)) \(metric.unit)")
    }
}

// MARK: - Sparkline View

/// Lightweight sparkline rendered as a Path.
struct SparklineView: View {
    let values: [Double]
    var lineColor: Color = .blue

    var body: some View {
        GeometryReader { geometry in
            if values.count >= 2,
               let minVal = values.min(),
               let maxVal = values.max() {
                let range = maxVal - minVal
                let effectiveRange = range > 0 ? range : 1.0

                Path { path in
                    let stepX = geometry.size.width / CGFloat(values.count - 1)
                    let height = geometry.size.height

                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = (value - minVal) / effectiveRange
                        let y = height - (CGFloat(normalized) * height * 0.8 + height * 0.1)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Formatting Helpers

/// Format a numeric value for compact widget display.
func formattedValue(_ value: Double?) -> String {
    guard let value else { return "--" }
    if value >= 10000 {
        return String(format: "%.0fK", value / 1000)
    } else if value >= 100 {
        return String(format: "%.0f", value)
    } else if value == value.rounded() && value >= 1 {
        return String(format: "%.0f", value)
    } else {
        return String(format: "%.1f", value)
    }
}
