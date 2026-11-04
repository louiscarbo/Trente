//
//  ShortcutsSetupSheet.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import FoundationModels
import SwiftUI

struct ShortcutsSetupSheet: View {
    var steps = ShortcutsSetupStep.walletAutomation(
        hasAppleIntelligence: ShortcutsSetupStep.opensOnDescribeScreen(SystemLanguageModel.default.availability)
    )
    var showsSteps = DeviceIdiom.isPhone

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stepIndex = 0
    @State private var isGoingForward = true

    var body: some View {
        NavigationStack {
            Group {
                if showsSteps {
                    ZStack {
                        stepPage
                    }
                    .safeAreaInset(edge: .bottom) {
                        StepNavigationBar(
                            showsPrevious: !isFirstStep,
                            nextTitle: nextTitle,
                            onPrevious: goBack,
                            onNext: next
                        )
                    }
                } else {
                    OtherDevicePage()
                }
            }
            .navigationTitle("Apple Pay")
            .inlineNavigationBarTitleDisplayMode()
            .toolbar {
                CloseToolbarItem { dismiss() }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 360)
        #endif
    }

    private var step: ShortcutsSetupStep {
        steps[stepIndex]
    }

    private var isFirstStep: Bool {
        stepIndex == 0
    }

    private var isLastStep: Bool {
        stepIndex == steps.count - 1
    }

    private var stepPage: some View {
        StepPage(
            instruction: step.instruction,
            imageName: step.imageName,
            showsPrivacyNote: isFirstStep,
            onOpenShortcuts: opensShortcutsFromPage
        )
        .id(stepIndex)
        .transition(stepTransition)
    }

    private var opensShortcutsFromPage: (() -> Void)? {
        guard !isFirstStep && !isLastStep else { return nil }
        return { openURL(ExternalLinks.shortcutsApp) }
    }

    private var nextTitle: LocalizedStringKey {
        if isFirstStep {
            "Open Shortcuts"
        } else if isLastStep {
            "Done"
        } else {
            "Next"
        }
    }

    private var stepTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .push(from: isGoingForward ? .trailing : .leading)
    }

    private func next() {
        if isLastStep {
            dismiss()
            return
        }
        if isFirstStep {
            openURL(ExternalLinks.newShortcut)
        }
        isGoingForward = true
        withAnimation {
            stepIndex += 1
        }
    }

    private func goBack() {
        isGoingForward = false
        withAnimation {
            stepIndex = max(stepIndex - 1, 0)
        }
    }
}

#Preview("iPhone") {
    ShortcutsSetupSheet(showsSteps: true)
}

#Preview("iPad and Mac") {
    ShortcutsSetupSheet(showsSteps: false)
}
