import SwiftUI

// MARK: - Quick Setup Step View

/// Final onboarding step: pick dashboard metrics and toggle sync.
struct QuickSetupStepView: View {

    // MARK: - Observed Objects

    @ObservedObject var viewModel: OnboardingViewModel

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                headerSection

                metricsSection

                syncToggle

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary)
                .accessibilityHidden(true)

            Text("Quick Setup")
                .font(AppTypography.displayLarge)
                .multilineTextAlignment(.center)

            Text("Pick the health categories you care about most for your dashboard, and choose whether to enable background sync.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dashboard Categories")
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text("\(viewModel.selectedMetricCount) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(viewModel.metrics) { metric in
                    metricChip(metric)
                }
            }
        }
        .padding(20)
        .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))
    }

    private func metricChip(_ metric: OnboardingViewModel.DashboardMetric) -> some View {
        Button {
            viewModel.toggleMetric(metric)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: metric.category.iconName)
                    .font(.body)
                    .accessibilityHidden(true)

                Text(metric.category.displayName)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                metric.isSelected ? AppColors.primary.opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        metric.isSelected ? AppColors.primary : AppColors.textSecondary.opacity(0.3),
                        lineWidth: metric.isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(metric.isSelected ? AppColors.primary : AppColors.textPrimary)
        .accessibilityLabel("\(metric.category.displayName), \(metric.isSelected ? "selected" : "not selected")")
        .accessibilityAddTraits(metric.isSelected ? .isSelected : [])
    }

    private var syncToggle: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.syncEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Background Sync")
                        .font(.subheadline.weight(.medium))

                    Text("Automatically sync selected health data between paired devices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))
    }
}
