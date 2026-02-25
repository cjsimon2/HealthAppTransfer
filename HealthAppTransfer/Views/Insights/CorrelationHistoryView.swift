import SwiftUI
import SwiftData
import Charts

// MARK: - Correlation History View

/// Shows the history of correlation analyses between two health metrics.
struct CorrelationHistoryView: View {

    // MARK: - Properties

    let typeA: HealthDataType
    let typeB: HealthDataType

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var records: [CorrelationRecord] = []

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if records.count >= 2 {
                    trendChart
                }

                if records.isEmpty {
                    emptyState
                } else {
                    recordsList
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .navigationTitle("Correlation History")
        .onAppear { loadRecords() }
    }

    // MARK: - Trend Chart

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("r-Value Over Time")
                .font(AppTypography.displaySmall)

            Chart(records, id: \.date) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("r", record.rValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppColors.primary.gradient)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", record.date),
                    y: .value("r", record.rValue)
                )
                .symbolSize(30)
                .foregroundStyle(AppColors.primary)
            }
            .chartYScale(domain: -1...1)
            .chartYAxis {
                AxisMarks(values: [-1, -0.5, 0, 0.5, 1])
            }
            .frame(height: 200)
            .accessibilityHidden(true)
        }
        .padding(12)
        .warmCard()
    }

    // MARK: - Records List

    private var recordsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Past Analyses")
                .font(AppTypography.displaySmall)

            ForEach(records, id: \.date) { record in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.date, style: .date)
                            .font(AppTypography.subheadlineMedium)

                        Text("\(record.pointCount) data points")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("r = \(record.rValue, specifier: "%.2f")")
                            .font(AppTypography.monoValueSmall)

                        Text(record.strengthLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .warmCard()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No history yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Run a correlation analysis to start building history.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Data Loading

    private func loadRecords() {
        let typeARaw = typeA.rawValue
        let typeBRaw = typeB.rawValue

        var descriptor = FetchDescriptor<CorrelationRecord>(
            predicate: #Predicate<CorrelationRecord> {
                $0.typeARaw == typeARaw && $0.typeBRaw == typeBRaw
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 30

        records = (try? modelContext.fetch(descriptor)) ?? []
    }
}
