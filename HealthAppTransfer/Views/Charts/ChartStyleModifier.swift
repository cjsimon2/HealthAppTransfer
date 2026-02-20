import SwiftUI
import Charts

// MARK: - Chart Colors

extension HealthDataCategory {

    /// Tint color for charts displaying data in this category.
    var chartColor: Color {
        switch self {
        case .activity: return .orange
        case .heart: return .red
        case .vitals: return .purple
        case .bodyMeasurements: return .blue
        case .metabolic: return .indigo
        case .nutrition: return .green
        case .respiratory: return .cyan
        case .mobility: return .teal
        case .fitness: return .mint
        case .audioExposure: return .yellow
        case .sleep: return .purple
        case .mindfulness: return .mint
        case .reproductiveHealth: return .pink
        case .symptoms: return .red
        case .other: return .gray
        case .workout: return .green
        case .characteristics: return .blue
        }
    }
}

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
