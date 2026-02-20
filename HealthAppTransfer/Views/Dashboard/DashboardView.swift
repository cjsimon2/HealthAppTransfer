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
            } else if viewModel.availableTypes.isEmpty {
                emptyState
            } else {
                dataOverview
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

            Text("No Health Data")
                .font(.title3.bold())

            Text("Authorize HealthKit access to see your health data overview.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var dataOverview: some View {
        List {
            Section {
                ForEach(viewModel.availableTypes, id: \.typeName) { item in
                    HStack {
                        Text(item.typeName)
                        Spacer()
                        Text("\(item.count) samples")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("\(viewModel.availableTypes.count) data types available")
            }
        }
    }
}
