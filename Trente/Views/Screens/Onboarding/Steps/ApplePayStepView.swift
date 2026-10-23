//
//  ApplePayStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct ApplePayStepView: View {
    let hasOpenedShortcut: Bool
    let onGetShortcut: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepLayout {
            OnboardingHeader(
                title: "Log Apple Pay purchases automatically",
                subtitle: "Add the Trente shortcut, then create one automation. Every card payment then shows up in Trente, ready to review."
            )
        } secondary: {
            OnboardingScrollPane {
                ShortcutsSetupCard(
                    title: "In the Shortcuts app",
                    systemImage: "creditcard",
                    steps: ShortcutsSetupCard.applePaySetupSteps
                )

                Label(
                    "Trente only receives the merchant name and the amount. Never your card details.",
                    systemImage: "lock.fill"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } actions: {
            if hasOpenedShortcut {
                OnboardingContinueButton(title: "Continue", action: onContinue)
                secondaryButton(title: "Open Shortcut Again", action: onGetShortcut)
            } else {
                OnboardingContinueButton(title: "Get the Shortcut", action: onGetShortcut)
                secondaryButton(title: "Set Up Later", action: onContinue)
            }
        }
    }

    private func secondaryButton(title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(TrenteSecondaryButtonStyle())
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    ApplePayStepView(hasOpenedShortcut: false, onGetShortcut: {}, onContinue: {})
}

#Preview("Compact, Shortcut Opened", traits: .fixedLayout(width: 390, height: 844)) {
    ApplePayStepView(hasOpenedShortcut: true, onGetShortcut: {}, onContinue: {})
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    ApplePayStepView(hasOpenedShortcut: false, onGetShortcut: {}, onContinue: {})
}
