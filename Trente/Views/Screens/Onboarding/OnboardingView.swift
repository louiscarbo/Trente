//
//  OnboardingView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = OnboardingModel(steps: OnboardingStep.availableSteps)
    @State private var saveErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            topBar
            stepContent
                .id(model.currentStep)
                .transition(stepTransition)
        }
        .clipped()
        .alert(
            "We couldn't save your month",
            isPresented: isShowingSaveError,
            presenting: saveErrorMessage
        ) { _ in
            Button("Retry", action: saveMonthAndContinue)
            Button("Cancel", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var topBar: some View {
        ZStack {
            PageIndicator(
                pages: model.steps,
                currentPage: .constant(model.currentStep)
            )
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(stepAccessibilityLabel)

            HStack {
                if model.canGoBack {
                    Button("Back", systemImage: "chevron.left", action: goBack)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .keyboardShortcut(.cancelAction)
                        .transition(.opacity)
                }
                Spacer()
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal)
        .padding(.top, DesignSystem.Spacing.small.rawValue)
    }

    @ViewBuilder
    private var stepContent: some View {
        @Bindable var model = model

        switch model.currentStep {
        case .welcome:
            WelcomeStepView(percentages: OnboardingModel.suggestedPercentages, onGetStarted: goForward)
        case .budget:
            BudgetStepView(
                startDate: $model.draft.startDate,
                currency: $model.draft.currency,
                budgetCents: $model.budgetCents,
                canContinue: model.canContinue,
                onContinue: goForward
            )
        case .split:
            SplitStepView(
                repartition: $model.draft.idealRepartition,
                isRepartitionComplete: $model.isRepartitionComplete,
                budgetCents: model.draft.idealBudgetCents,
                currency: model.draft.currency,
                onContinue: saveMonthAndContinue
            )
        case .notifications, .applePay, .allSet:
            OnboardingStepLayout {
                Text(verbatim: "\(model.currentStep)")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } secondary: {
                Color.clear
            } actions: {
                OnboardingContinueButton(title: "Continue", action: goForward)
            }
        }
    }

    private var stepTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        switch model.direction {
        case .forward:
            return .push(from: .trailing)
        case .backward:
            return .push(from: .leading)
        }
    }

    private var stepAccessibilityLabel: Text {
        let position = (model.steps.firstIndex(of: model.currentStep) ?? 0) + 1
        return Text("Step \(position) of \(model.steps.count)")
    }

    private var isShowingSaveError: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private func saveMonthAndContinue() {
        do {
            try model.saveMonth(in: modelContext)
            goForward()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func goForward() {
        guard !model.isLastStep else {
            onFinish()
            return
        }
        withAnimation {
            model.goForward()
        }
    }

    private func goBack() {
        withAnimation {
            model.goBack()
        }
    }
}

#Preview {
    OnboardingView {}
        .modelContainer(DataProvider.shared.modelContainer)
}
