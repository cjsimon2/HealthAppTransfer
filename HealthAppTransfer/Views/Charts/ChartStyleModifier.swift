import SwiftUI
import Charts

// MARK: - Chart Style Modifier

/// Applies consistent axis formatting and category-specific color to a Chart.
struct ChartStyleModifier: ViewModifier {
    let category: HealthDataCategory

    func body(content: Content) -> some View {
        content
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .foregroundStyle(category.chartColor.gradient)
    }
}

// MARK: - View Extension

extension View {
    /// Applies the standard health chart style with category-appropriate color.
    func healthChartStyle(for category: HealthDataCategory) -> some View {
        modifier(ChartStyleModifier(category: category))
    }
}
