import SwiftUI
import SwiftData

// MARK: - Insights View

struct InsightsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: - Observed Objects

    @StateObject private var viewModel: InsightsViewModel

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    // MARK: - State

    @State private var showGoalSettings = false

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
        _viewModel = StateObject(wrappedValue: InsightsViewModel(healthKitService: healthKitService))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if sizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .navigationTitle("Insights")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showGoalSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Goal Settings")
                .accessibilityIdentifier("insights.goalSettings")
            }
        }
        .sheet(isPresented: $showGoalSettings) {
            GoalSettingsView()
        }
        .onChange(of: showGoalSettings) { _, isShowing in
            if !isShowing {
                Task { await viewModel.loadInsights(modelContext: modelContext) }
            }
        }
        .task {
            viewModel.loadFavorites(modelContext: modelContext)
            await viewModel.loadInsights(modelContext: modelContext)
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 24) {
            insightsSection
            correlationSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 100)
    }

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            // Left column: insights as adaptive grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 12) {
                Text("Weekly Insights")
                    .font(AppTypography.displaySmall)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gridCellColumns(2)

                if viewModel.isLoadingInsights {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else if viewModel.insights.isEmpty {
                    emptyInsightsState
                } else {
                    ForEach(viewModel.insights) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Right column: correlations
            VStack(alignment: .leading, spacing: 12) {
                correlationSection
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 100)
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Insights")
                .font(AppTypography.displaySmall)

            if viewModel.isLoadingInsights {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if viewModel.insights.isEmpty {
                emptyInsightsState
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.insights) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            }
        }
    }

    private var emptyInsightsState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.dots.scatter")
                .font(.title)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Not enough data yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Insights appear after a week of health data.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Correlation Section

    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Correlations")
                .font(AppTypography.displaySmall)

            metricPickers
            compareButton
            suggestedPairsRow

            if viewModel.isLoadingCorrelation {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if let result = viewModel.correlationResult {
                CorrelationChartView(result: result)

                Button {
                    viewModel.toggleFavorite(
                        typeA: viewModel.selectedMetricA,
                        typeB: viewModel.selectedMetricB,
                        modelContext: modelContext
                    )
                } label: {
                    let isFav = viewModel.isFavorite(
                        typeA: viewModel.selectedMetricA,
                        typeB: viewModel.selectedMetricB
                    )
                    Label(
                        isFav ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: isFav ? "star.fill" : "star"
                    )
                    .font(.subheadline)
                    .foregroundStyle(isFav ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("insights.favoriteToggle")

                if !result.points.isEmpty {
                    NavigationLink {
                        CorrelationHistoryView(
                            typeA: viewModel.selectedMetricA,
                            typeB: viewModel.selectedMetricB
                        )
                    } label: {
                        Label("View History", systemImage: "clock.arrow.circlepath")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primary)
                    }
                    .accessibilityIdentifier("insights.correlationHistory")
                }
            }
        }
    }

    private var metricPickers: some View {
        VStack(spacing: 8) {
            Picker("Metric A", selection: $viewModel.selectedMetricA) {
                ForEach(quantityTypes, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .accessibilityIdentifier("insights.pickerA")

            Picker("Metric B", selection: $viewModel.selectedMetricB) {
                ForEach(quantityTypes, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .accessibilityIdentifier("insights.pickerB")
        }
    }

    private var compareButton: some View {
        Button {
            Task { await viewModel.loadCorrelation(modelContext: modelContext) }
        } label: {
            Label("Compare", systemImage: "chart.dots.scatter")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.selectedMetricA == viewModel.selectedMetricB)
        .accessibilityIdentifier("insights.compareButton")
    }

    private var suggestedPairsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested")
                .font(AppTypography.captionMedium)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.orderedSuggestedPairs(), id: \.0) { pair in
                        Button {
                            viewModel.selectedMetricA = pair.0
                            viewModel.selectedMetricB = pair.1
                            Task { await viewModel.loadCorrelation(modelContext: modelContext) }
                        } label: {
                            HStack(spacing: 4) {
                                if viewModel.isFavorite(typeA: pair.0, typeB: pair.1) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }
                                Text("\(shortName(pair.0)) vs \(shortName(pair.1))")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColors.primary.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Compare \(pair.0.displayName) and \(pair.1.displayName)")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var quantityTypes: [HealthDataType] {
        HealthDataType.allCases.filter(\.isQuantityType)
    }

    private func shortName(_ type: HealthDataType) -> String {
        let name = type.displayName
        // Truncate long names for chip display
        if name.count > 12 {
            return String(name.prefix(10)) + "..."
        }
        return name
    }
}
