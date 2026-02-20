import SwiftUI

// MARK: - Health Data Detail View

struct HealthDataDetailView: View {

    // MARK: - Observed Objects

    @StateObject private var viewModel: HealthDataDetailViewModel

    // MARK: - State

    @State private var showingExportShare = false

    // MARK: - Init

    init(dataType: HealthDataType, healthKitService: HealthKitService) {
        _viewModel = StateObject(wrappedValue: HealthDataDetailViewModel(
            dataType: dataType,
            healthKitService: healthKitService
        ))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading \(viewModel.dataType.displayName)...")
            } else {
                contentView
            }
        }
        .navigationTitle(viewModel.dataType.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                exportButton
            }
        }
        .task { await viewModel.loadData() }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.dataType.isQuantityType {
                    chartSection
                    statsCard
                }

                if !viewModel.recentDTOs.isEmpty {
                    recentSamplesSection
                }

                if viewModel.samples.isEmpty && viewModel.recentDTOs.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chart")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HealthChartView(
                dataType: viewModel.dataType,
                aggregationEngine: viewModel.aggregationEngine
            )
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statItem(title: "Latest", value: viewModel.latestValue)
                statItem(title: "Average", value: viewModel.avgValue)
                statItem(title: "Min", value: viewModel.minValue)
                statItem(title: "Max", value: viewModel.maxValue)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityIdentifier("detail.stat.\(title.lowercased())")
    }

    // MARK: - Recent Samples

    private var recentSamplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Samples")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ForEach(viewModel.recentDTOs) { dto in
                sampleRow(dto)
            }
        }
    }

    private func sampleRow(_ dto: HealthSampleDTO) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dto.startDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.subheadline.weight(.medium))

                Text(dto.sourceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let value = dto.value, let unit = dto.unit {
                Text(formatDTOValue(value, unit: unit))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(viewModel.dataType.category.chartColor)
            } else if let categoryValue = dto.categoryValue {
                Text("\(categoryValue)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(sampleRowLabel(dto))
    }

    private func sampleRowLabel(_ dto: HealthSampleDTO) -> String {
        let date = dto.startDate.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        if let value = dto.value, let unit = dto.unit {
            return "\(formatDTOValue(value, unit: unit)), \(date), from \(dto.sourceName)"
        } else if let categoryValue = dto.categoryValue {
            return "Value \(categoryValue), \(date), from \(dto.sourceName)"
        }
        return "\(date), from \(dto.sourceName)"
    }

    // MARK: - Export Button

    private var exportButton: some View {
        ShareLink(
            item: exportData,
            preview: SharePreview(
                "\(viewModel.dataType.displayName) Export",
                image: Image(systemName: "square.and.arrow.up")
            )
        )
        .disabled(viewModel.recentDTOs.isEmpty)
        .accessibilityLabel("Export \(viewModel.dataType.displayName) data")
        .accessibilityIdentifier("detail.exportButton")
    }

    private var exportData: Data {
        viewModel.exportJSON() ?? Data()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Data")
                .font(.title3.bold())

            Text("No \(viewModel.dataType.displayName) data available.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    // MARK: - Helpers

    private func formatDTOValue(_ value: Double, unit: String) -> String {
        if value == value.rounded() {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }
}
