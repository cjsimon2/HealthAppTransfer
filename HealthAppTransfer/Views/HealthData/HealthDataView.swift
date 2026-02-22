import SwiftUI
import SwiftData

// MARK: - Health Data View

struct HealthDataView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Observed Objects

    @StateObject private var viewModel: HealthDataViewModel

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
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
        .task { await viewModel.loadDataTypes(modelContext: modelContext) }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            Text("No Health Data")
                .font(.title2.bold())

            #if os(macOS)
            Text("Sync health data from your iPhone to browse available types.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            #else
            Text("Authorize HealthKit access to browse your health data types.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            #endif

            Spacer()
        }
    }

    private var dataTypeList: some View {
        List {
            ForEach(viewModel.filteredGroups) { group in
                Section {
                    ForEach(group.types) { typeInfo in
                        if typeInfo.type.isSampleBased {
                            NavigationLink {
                                HealthDataDetailView(
                                    dataType: typeInfo.type,
                                    healthKitService: healthKitService
                                )
                            } label: {
                                typeRow(typeInfo)
                            }
                        } else {
                            typeRow(typeInfo)
                        }
                    }
                } header: {
                    Label(group.category.displayName, systemImage: group.category.iconName)
                        .accessibilityLabel("\(group.category.displayName) category, \(group.types.count) types")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search health types")
        .accessibilityIdentifier("healthData.list")
    }

    private func typeRow(_ typeInfo: HealthDataViewModel.TypeInfo) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(typeInfo.type.category.chartColor.gradient)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
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
                Text("\(typeInfo.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.fill.quaternary, in: Capsule())
                    .accessibilityLabel("Has data")
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(typeInfo.displayName), \(typeInfo.count > 0 ? "\(typeInfo.count) samples" : "no data")")
        .accessibilityIdentifier("healthData.row.\(typeInfo.type.rawValue)")
    }
}
