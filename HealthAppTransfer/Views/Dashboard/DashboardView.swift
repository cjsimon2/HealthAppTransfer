import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {

    // MARK: - Observed Objects

    @StateObject private var viewModel: DashboardViewModel

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(healthKitService: healthKitService))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading health overview...")
            } else if viewModel.categories.isEmpty {
                emptyState
            } else {
                categoryOverview
            }
        }
        .navigationTitle("Dashboard")
        .task { await viewModel.loadOverview() }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Health Data")
                .font(.title3.bold())

            Text("Authorize HealthKit access to see your health data overview.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var categoryOverview: some View {
        ScrollView {
            VStack(spacing: 8) {
                summaryHeader

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(viewModel.categories) { summary in
                        categoryCard(summary)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 100)
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.totalAvailable)")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("data types with data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.totalAvailable) data types with data")
    }

    private func categoryCard(_ summary: DashboardViewModel.CategorySummary) -> some View {
        VStack(spacing: 8) {
            Image(systemName: summary.category.iconName)
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(summary.category.displayName)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            Text("\(summary.availableCount)/\(summary.totalTypes)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.category.displayName): \(summary.availableCount) of \(summary.totalTypes) types have data")
    }
}
