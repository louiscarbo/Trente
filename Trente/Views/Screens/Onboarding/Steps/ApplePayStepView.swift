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
                title: "Log Apple Pay in a tap",
                subtitle: "A Shortcuts automation sends each Apple Pay payment to Trente. You review it, Trente files it."
            )
        } secondary: {
            OnboardingScrollPane {
                ShortcutsSetupCard(
                    title: "Set up the automation",
                    systemImage: "wallet.pass",
                    steps: [
                        "Tap Get the Shortcut and add Log Wallet Transaction to your shortcuts.",
                        "In the Shortcuts app, open Automation and tap +.",
                        "Choose Wallet, pick your cards, then choose Run Immediately.",
                        "Add the Run Shortcut action, pick Log Wallet Transaction and pass it the Shortcut Input."
                    ]
                )
                Label(
                    "You can set this up later from the Shortcuts app.",
                    systemImage: "info.circle"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } actions: {
            OnboardingContinueButton(title: "Get the Shortcut", action: onGetShortcut)
            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
        }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    ApplePayStepView(onGetShortcut: {}, onContinue: {})
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    ApplePayStepView(onGetShortcut: {}, onContinue: {})
}
