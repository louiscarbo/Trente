//
//  ApplePayStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct ApplePayStepView: View {
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
                    steps: [
                        "Tap **Get the Shortcut** below and add **Log Wallet Transaction** to your shortcuts.",
                        "In the **Automation** tab, create a new automation with the **Wallet** trigger, choose your cards and select **Run Immediately**.",
                        "Add **Run Shortcut**, pick **Log Wallet Transaction** and pass it the **Shortcut Input**."
                    ]
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
            OnboardingContinueButton(title: "Get the Shortcut", action: onGetShortcut)
            Button(action: onContinue) {
                Text("Set Up Later")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TrenteSecondaryButtonStyle())
        }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    ApplePayStepView(onGetShortcut: {}, onContinue: {})
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    ApplePayStepView(onGetShortcut: {}, onContinue: {})
}
