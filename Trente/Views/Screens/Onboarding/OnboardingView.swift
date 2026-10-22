//
//  OnboardingView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var model = OnboardingModel(steps: OnboardingStep.availableSteps)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            topBar
            stepContent
                .id(model.currentStep)
                .transition(stepTransition)
        }
        .clipped()
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
        OnboardingStepLayout {
            Text(verbatim: "\(model.currentStep)")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
        } secondary: {
            Color.clear
        } actions: {
            Button("Continue", action: goForward)
                .buttonStyle(TrentePrimaryButtonStyle())
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
}
