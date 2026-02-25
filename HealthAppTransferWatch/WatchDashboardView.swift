import SwiftUI

// MARK: - Watch Dashboard View

/// Main dashboard showing today's health metrics on Apple Watch.
struct WatchDashboardView: View {

    // MARK: - Properties

    @ObservedObject var connectivityManager: WatchConnectivityManager

    // MARK: - State

    @State private var snapshots: [WidgetMetricSnapshot] = []
    @State private var streakData: [String: Int] = [:]
    @State private var goalProgress: [String: Double] = [:]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if snapshots.isEmpty {
                    emptyState
                } else {
                    metricsSection
                    streakSection
                }
            }
            .navigationTitle("Health")
            .refreshable { loadData() }
            .onAppear { loadData() }
        }
    }

    // MARK: - Sections

    private var metricsSection: some View {
        Section("Today") {
            ForEach(snapshots) { snapshot in
                WatchMetricRowView(snapshot: snapshot)
            }
        }
    }

    @ViewBuilder
    private var streakSection: some View {
        let activeStreaks = streakData.filter { $0.value >= 3 }
        if !activeStreaks.isEmpty {
            Section("Streaks") {
                ForEach(activeStreaks.sorted(by: { $0.value > $1.value }), id: \.key) { key, days in
                    HStack {
                        Image(systemName: "flame")
                            .foregroundStyle(.orange)
                        Text(key.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: ""))
                        Spacer()
                        Text("\(days)d")
                            .font(.headline)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.text.square")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No data yet")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Open the iPhone app to sync.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }

    // MARK: - Data Loading

    private func loadData() {
        let store = WidgetDataStore.shared
        snapshots = store.loadAll()
        streakData = store.loadStreakData()
        goalProgress = store.loadGoalProgress()
    }
}
