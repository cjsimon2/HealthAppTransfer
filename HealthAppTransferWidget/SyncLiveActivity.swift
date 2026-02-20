import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Sync Live Activity

struct SyncLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SyncActivityAttributes.self) { context in
            LockScreenSyncView(
                attributes: context.attributes,
                state: context.state
            )
            .activityBackgroundTint(.blue.opacity(0.15))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text("\(context.state.typesSynced)/\(context.attributes.totalTypes)")
                    } icon: {
                        Image(systemName: "heart.text.clipboard")
                    }
                    .font(.caption)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.title2.bold())
                        .foregroundStyle(progressColor(for: context.state.status))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progress)
                            .tint(progressColor(for: context.state.status))

                        HStack {
                            Text(context.state.currentTypeName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(context.state.totalSamples) samples")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(progressColor(for: context.state.status))
            } minimal: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.blue)
            }
        }
    }

    private func progressColor(
        for status: SyncActivityAttributes.ContentState.Status
    ) -> Color {
        switch status {
        case .syncing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenSyncView: View {
    let attributes: SyncActivityAttributes
    let state: SyncActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 12) {
            headerRow
            progressBar
            detailRow
        }
        .padding(16)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Image(systemName: "heart.text.clipboard")
                .foregroundStyle(.blue)
            Text("Health Data Sync")
                .font(.headline)
            Spacer()
            statusBadge
        }
    }

    private var progressBar: some View {
        ProgressView(value: state.progress)
            .tint(state.status == .completed ? .green : .blue)
    }

    private var detailRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.currentTypeName)
                    .font(.subheadline)
                Text("\(state.typesSynced) of \(attributes.totalTypes) types")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(state.totalSamples)")
                    .font(.subheadline.bold())
                Text("samples")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch state.status {
        case .syncing:
            Text("\(Int(state.progress * 100))%")
                .font(.caption.bold())
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.15), in: Capsule())
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}
