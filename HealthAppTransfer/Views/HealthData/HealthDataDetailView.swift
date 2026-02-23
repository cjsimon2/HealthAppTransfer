import SwiftUI

// MARK: - Health Data Detail View

struct HealthDataDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Observed Objects

    @StateObject private var viewModel: HealthDataDetailViewModel

    // MARK: - State

    @State private var showingExportShare = false
    @State private var exportFileURL: URL?

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
        .task { await viewModel.loadData(modelContext: modelContext) }
        .sheet(isPresented: $showingExportShare) {
            if let url = exportFileURL {
                ShareSheetView(fileURL: url) {
                    ShareFileHelper.cleanupTempFiles()
                    exportFileURL = nil
                }
            }
        }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trends")
                    .font(AppTypography.displaySmall)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Image(systemName: viewModel.dataType.category.iconName)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.dataType.category.chartColor)
            }

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
                .font(AppTypography.displaySmall)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statItem(title: "Latest", value: viewModel.latestValue)
                statItem(title: "Average", value: viewModel.avgValue)
                statItem(title: "Min", value: viewModel.minValue)
                statItem(title: "Max", value: viewModel.maxValue)
            }
        }
        .padding(16)
        .warmCard()
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(viewModel.dataType.category.chartColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityIdentifier("detail.stat.\(title.lowercased())")
    }

    // MARK: - Recent Samples

    private var recentSamplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Samples")
                .font(AppTypography.displaySmall)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentDTOs.enumerated()), id: \.element.id) { index, dto in
                    sampleRow(dto)

                    if index < viewModel.recentDTOs.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
                    .font(.body.bold().monospacedDigit())
                    .foregroundStyle(viewModel.dataType.category.chartColor)
            } else if let categoryValue = dto.categoryValue {
                Text("\(categoryValue)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
        Button {
            if let url = viewModel.exportToFile() {
                exportFileURL = url
                showingExportShare = true
            }
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .disabled(viewModel.recentDTOs.isEmpty)
        .accessibilityLabel("Export \(viewModel.dataType.displayName) data")
        .accessibilityIdentifier("detail.exportButton")
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
