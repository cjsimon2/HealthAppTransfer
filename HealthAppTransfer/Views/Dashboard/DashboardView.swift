import SwiftUI
import SwiftData

// MARK: - Dashboard View

struct DashboardView: View {

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]

    // MARK: - Observed Objects

    @StateObject private var viewModel: DashboardViewModel

    // MARK: - State

    @State private var showingMetricPicker = false

    // MARK: - Dependencies

    private let healthKitService: HealthKitService

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
        _viewModel = StateObject(wrappedValue: DashboardViewModel(healthKitService: healthKitService))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.cards.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading dashboard...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.cards.isEmpty {
                emptyState
            } else {
                metricGrid
            }
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingMetricPicker = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Configure dashboard metrics")
                .accessibilityIdentifier("dashboard.configureButton")
            }
        }
        .sheet(isPresented: $showingMetricPicker) {
            MetricPickerSheet(
                selectedTypes: configuredTypes,
                onSave: saveMetricTypes
            )
        }
        .task { await viewModel.loadMetrics(configuredTypes: configuredTypes, modelContext: modelContext) }
    }

    // MARK: - Configured Types

    private var configuredTypes: [HealthDataType] {
        guard let prefs = preferences.first, !prefs.dashboardMetricTypes.isEmpty else {
            return []
        }
        return prefs.dashboardMetricTypes.compactMap { HealthDataType(rawValue: $0) }
    }

    private func saveMetricTypes(_ types: [HealthDataType]) {
        if let prefs = preferences.first {
            prefs.dashboardMetricTypes = types.map(\.rawValue)
            prefs.updatedAt = Date()
        }
        Task { await viewModel.loadMetrics(configuredTypes: types, modelContext: modelContext) }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            Text("No Health Data")
                .font(.title2.bold())

            #if os(macOS)
            Text("Sync health data from your iPhone via CloudKit or LAN to see your overview.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            #else
            Text("Authorize HealthKit access to see your health data overview.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            #endif

            Button {
                showingMetricPicker = true
            } label: {
                Label("Configure Dashboard", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 4)
            .accessibilityIdentifier("dashboard.emptyState.configureButton")

            Spacer()
        }
    }

    private var metricGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.cards) { card in
                    NavigationLink {
                        HealthDataDetailView(
                            dataType: card.dataType,
                            healthKitService: healthKitService
                        )
                    } label: {
                        MetricCardView(
                            dataType: card.dataType,
                            latestValue: card.latestValue,
                            samples: card.samples,
                            trendDirection: card.trend
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Double tap to view details")
                    .accessibilityIdentifier("dashboard.card.\(card.dataType.rawValue)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }

    private var gridColumns: [GridItem] {
        let minWidth: CGFloat = sizeClass == .regular ? 180 : 150
        return [GridItem(.adaptive(minimum: minWidth), spacing: 12)]
    }
}

// MARK: - Metric Picker Sheet

/// Sheet for choosing which metrics appear on the dashboard.
private struct MetricPickerSheet: View {

    // MARK: - State

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<HealthDataType>

    // MARK: - Properties

    let onSave: ([HealthDataType]) -> Void

    // MARK: - Init

    init(selectedTypes: [HealthDataType], onSave: @escaping ([HealthDataType]) -> Void) {
        let types = selectedTypes.isEmpty ? DashboardViewModel.defaultMetricTypes : selectedTypes
        _selected = State(initialValue: Set(types))
        self.onSave = onSave
    }

    // MARK: - Quantity Types

    private var quantityGroups: [(category: HealthDataCategory, types: [HealthDataType])] {
        HealthDataType.groupedByCategory.compactMap { group in
            let quantityTypes = group.types.filter(\.isQuantityType)
            guard !quantityTypes.isEmpty else { return nil }
            return (category: group.category, types: quantityTypes)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                ForEach(quantityGroups, id: \.category) { group in
                    Section(group.category.displayName) {
                        ForEach(group.types, id: \.self) { type in
                            Button {
                                toggleType(type)
                            } label: {
                                HStack {
                                    Image(systemName: group.category.iconName)
                                        .foregroundStyle(group.category.chartColor)
                                        .frame(width: 24)

                                    Text(type.displayName)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selected.contains(type) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .accessibilityLabel("\(type.displayName), \(selected.contains(type) ? "selected" : "not selected")")
                        }
                    }
                }
            }
            .navigationTitle("Dashboard Metrics")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Preserve order: match allCases order for consistency
                        let ordered = HealthDataType.allCases.filter { selected.contains($0) }
                        onSave(ordered)
                        dismiss()
                    }
                    .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func toggleType(_ type: HealthDataType) {
        if selected.contains(type) {
            selected.remove(type)
        } else {
            selected.insert(type)
        }
    }
}
