import SwiftUI

// MARK: - Health Data View

struct HealthDataView: View {

    // MARK: - Observed Objects

    @StateObject private var viewModel: HealthDataViewModel

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        _viewModel = StateObject(wrappedValue: HealthDataViewModel(healthKitService: healthKitService))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading health data types...")
            } else if viewModel.isEmpty {
                emptyState
            } else {
                dataTypeList
            }
        }
        .navigationTitle("Health Data")
        .task { await viewModel.loadDataTypes() }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Health Data")
                .font(.title3.bold())

            Text("Authorize HealthKit access to browse your health data types.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var dataTypeList: some View {
        List {
            ForEach(viewModel.filteredGroups) { group in
                Section {
                    ForEach(group.types) { typeInfo in
                        typeRow(typeInfo)
                    }
                } header: {
                    Label(group.category.displayName, systemImage: group.category.iconName)
                        .accessibilityLabel("\(group.category.displayName) category, \(group.types.count) types")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search health types")
    }

    private func typeRow(_ typeInfo: HealthDataViewModel.TypeInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(typeInfo.displayName)
                    .font(.body.weight(.medium))

                if typeInfo.count > 0 {
                    Text("\(typeInfo.count) samples")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if typeInfo.count > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                    .accessibilityLabel("Has data")
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(typeInfo.displayName), \(typeInfo.count > 0 ? "\(typeInfo.count) samples" : "no data")")
    }
}
