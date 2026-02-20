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
            } else if viewModel.dataTypes.isEmpty {
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
            ForEach(viewModel.dataTypes, id: \.typeName) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.typeName)
                            .font(.body.weight(.medium))

                        Text("\(item.count) samples")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
