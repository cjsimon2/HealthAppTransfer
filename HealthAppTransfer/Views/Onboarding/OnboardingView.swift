import SwiftUI
import SwiftData

// MARK: - Onboarding View

/// 4-step onboarding flow using PageTabViewStyle.
/// Shown on first launch; stores completion in UserPreferences.
struct OnboardingView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @StateObject private var viewModel: OnboardingViewModel

    // MARK: - Callbacks

    let onComplete: () -> Void

    // MARK: - Init

    init(healthKitService: HealthKitService, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(healthKitService: healthKitService))
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $viewModel.currentStep) {
                ForEach(viewModel.activeSteps, id: \.self) { step in
                    stepView(for: step)
                        .tag(step)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif

            bottomBar
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - Step Router

    @ViewBuilder
    private func stepView(for step: OnboardingViewModel.Step) -> some View {
        switch step {
        case .welcome:
            WelcomeStepView()
        case .healthKit:
            HealthKitStepView(
                isAuthorized: viewModel.healthKitAuthorized,
                isRequesting: viewModel.isRequestingHealthKit,
                onAuthorize: { await viewModel.requestHealthKitAuth() }
            )
        case .notifications:
            NotificationStepView(
                isAuthorized: viewModel.notificationsAuthorized,
                isRequesting: viewModel.isRequestingNotifications,
                onAuthorize: { await viewModel.requestNotificationPermission() }
            )
        case .quickSetup:
            QuickSetupStepView(viewModel: viewModel)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 16) {
            pageIndicator

            HStack {
                skipButton

                Spacer()

                if viewModel.isLastStep {
                    finishButton
                } else {
                    nextButton
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.activeSteps, id: \.self) { step in
                Capsule()
                    .fill(step == viewModel.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: step == viewModel.currentStep ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
            }
        }
        .padding(.top, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(viewModel.currentStepIndex + 1) of \(viewModel.activeSteps.count)")
    }

    private var skipButton: some View {
        Button("Skip") {
            finishOnboarding()
        }
        .foregroundStyle(.secondary)
        .accessibilityLabel("Skip onboarding")
    }

    private var nextButton: some View {
        Button {
            viewModel.nextStep()
        } label: {
            Text("Next")
                .fontWeight(.semibold)
                .frame(minWidth: 80)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityLabel("Next step")
    }

    private var finishButton: some View {
        Button {
            finishOnboarding()
        } label: {
            Text("Get Started")
                .fontWeight(.semibold)
                .frame(minWidth: 120)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityLabel("Finish onboarding and start using the app")
    }

    // MARK: - Actions

    private func finishOnboarding() {
        viewModel.completeOnboarding(context: modelContext)
        onComplete()
    }
}
