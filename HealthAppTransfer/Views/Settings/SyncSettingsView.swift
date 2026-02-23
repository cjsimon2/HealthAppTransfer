import SwiftData
import SwiftUI

// MARK: - Sync Settings View

struct SyncSettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Observed Objects

    @StateObject private var viewModel: SyncSettingsViewModel

    // MARK: - State

    @State private var showTypePicker = false

    // MARK: - Init

    init(healthKitService: HealthKitService) {
        _viewModel = StateObject(wrappedValue: SyncSettingsViewModel(healthKitService: healthKitService))
    }

    // MARK: - Body

    var body: some View {
        List {
            syncTogglesSection
            frequencySection
            typeSelectionSection
            syncNowSection
            syncHistorySection
            dataUsageSection
        }
        .navigationTitle("Sync Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            viewModel.loadConfiguration(from: modelContext)
        }
        .sheet(isPresented: $showTypePicker) {
            typePicker
        }
    }

    // MARK: - Sync Toggles

    private var syncTogglesSection: some View {
        Section {
            Toggle(isOn: cloudKitBinding) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CloudKit Sync")
                        Text("Sync via iCloud across devices")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "icloud")
                }
            }
            .accessibilityIdentifier("syncSettings.cloudKit")

            Toggle(isOn: lanSyncBinding) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAN Sync")
                        Text("Sync over local network")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "wifi")
                }
            }
            .accessibilityIdentifier("syncSettings.lanSync")
        } header: {
            Text("Sync Methods")
        }
    }

    // MARK: - Frequency

    private var frequencySection: some View {
        Section {
            Picker("Frequency", selection: frequencyBinding) {
                ForEach(SyncFrequency.allCases) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            .accessibilityIdentifier("syncSettings.frequency")
        } header: {
            Text("Sync Frequency")
        } footer: {
            Text("How often to automatically sync health data in the background.")
        }
    }

    // MARK: - Type Selection

    private var typeSelectionSection: some View {
        Section {
            Button {
                showTypePicker = true
            } label: {
                HStack {
                    Label("Health Types", systemImage: "heart.text.square")
                    Spacer()
                    Text("\(viewModel.enabledTypes.count) selected")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
            .accessibilityIdentifier("syncSettings.typesPicker")
        } header: {
            Text("Data Types")
        } footer: {
            Text("Choose which health data types to include in sync.")
        }
    }

    // MARK: - Sync Now

    private var syncNowSection: some View {
        Section {
            Button {
                Task { await viewModel.syncNow(context: modelContext) }
            } label: {
                HStack {
                    if viewModel.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                        Text(viewModel.syncProgress ?? "Syncing...")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isSyncing || viewModel.enabledTypes.isEmpty || !HealthKitService.isAvailable)
            .accessibilityIdentifier("syncSettings.syncNow")

            if let lastSync = viewModel.lastSyncDate {
                HStack {
                    Text("Last sync")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundStyle(.secondary)
                    Text("ago")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            if let error = viewModel.error {
                Label {
                    Text(error)
                        .font(.caption)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("Manual Sync")
        }
    }

    // MARK: - Sync History

    private var syncHistorySection: some View {
        Section {
            if viewModel.syncHistory.isEmpty {
                Text("No sync history yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.syncHistory) { entry in
                    syncHistoryRow(entry)
                }
            }
        } header: {
            Text("Recent Syncs")
        }
    }

    private func syncHistoryRow(_ entry: SyncHistoryEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.sourceIcon)
                .font(.caption)
                .foregroundStyle(entry.success ? .green : .red)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.sourceDisplayName)
                        .font(.subheadline.weight(.medium))
                    if !entry.success {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }

                HStack(spacing: 8) {
                    Text(entry.date, style: .relative)
                    Text("ago")
                    if entry.success {
                        Text("\(entry.sampleCount) samples")
                            .foregroundStyle(.secondary)
                    } else if let errorMsg = entry.errorMessage {
                        Text(errorMsg)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Data Usage

    private var dataUsageSection: some View {
        Section {
            HStack {
                Label("CloudKit Records", systemImage: "icloud")
                Spacer()
                Text("~\(viewModel.cloudKitRecordCount)")
                    .foregroundStyle(.secondary)
            }

            if let lastCloudKit = viewModel.lastCloudKitSyncDate {
                HStack {
                    Text("Last CloudKit sync")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(lastCloudKit, style: .relative)
                        .foregroundStyle(.secondary)
                    Text("ago")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            HStack {
                Label("Local Samples", systemImage: "internaldrive")
                Spacer()
                Text("\(viewModel.lastSyncSampleCount)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Synced Types", systemImage: "list.bullet")
                Spacer()
                Text("\(viewModel.enabledTypes.count) of \(HealthDataType.allCases.filter(\.isSampleBased).count)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Data Usage")
        }
    }

    // MARK: - Type Picker Sheet

    private var typePicker: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button("Select All") {
                            viewModel.selectAllTypes(context: modelContext)
                        }
                        Spacer()
                        Button("Deselect All") {
                            viewModel.deselectAllTypes(context: modelContext)
                        }
                    }
                    .buttonStyle(.borderless)
                }

                ForEach(HealthDataType.groupedByCategory, id: \.category) { group in
                    Section {
                        ForEach(group.types.filter(\.isSampleBased), id: \.rawValue) { type in
                            Toggle(isOn: typeBinding(for: type.rawValue)) {
                                Label(type.displayName, systemImage: group.category.iconName)
                            }
                            .toggleStyle(.switch)
                        }
                    } header: {
                        Text(group.category.displayName)
                    }
                }
            }
            .navigationTitle("Health Types")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showTypePicker = false }
                }
            }
            #endif
        }
        .frame(minWidth: 400, minHeight: 500)
    }

    // MARK: - Bindings

    private var cloudKitBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isCloudKitEnabled },
            set: { newValue in
                viewModel.isCloudKitEnabled = newValue
                viewModel.saveConfiguration(to: modelContext)
            }
        )
    }

    private var lanSyncBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isLANSyncEnabled },
            set: { newValue in
                viewModel.isLANSyncEnabled = newValue
                viewModel.saveConfiguration(to: modelContext)
            }
        )
    }

    private var frequencyBinding: Binding<SyncFrequency> {
        Binding(
            get: { viewModel.syncFrequency },
            set: { newValue in
                viewModel.syncFrequency = newValue
                viewModel.saveConfiguration(to: modelContext)
            }
        )
    }

    private func typeBinding(for rawValue: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.enabledTypes.contains(rawValue) },
            set: { _ in
                viewModel.toggleType(rawValue, context: modelContext)
            }
        )
    }
}
