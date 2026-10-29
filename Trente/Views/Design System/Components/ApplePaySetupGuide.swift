//
//  ApplePaySetupGuide.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import SwiftUI

struct ApplePaySetupGuide: View {
    static let steps: [LocalizedStringKey] = [
        "Tap **Get the Shortcut** below and add **Trente & Apple Pay** to your shortcuts.",
        "Tap the **Trente & Apple Pay** shortcut you just added, then tap **Edit**.",
        "In the menu at the bottom of the screen, tap the **Automation** category, then scroll down to the **Wallet** row. Tap **Wallet – When I tap a Wallet card**.",
        "You should see two blocks in your automation. You're all set: Trente will receive your next Apple Pay purchases!"
    ]

    var body: some View {
        VStack(spacing: .medium) {
            ShortcutsSetupCard(
                title: "In the Shortcuts app",
                systemImage: "creditcard",
                steps: Self.steps
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
    }
}

#Preview {
    ApplePaySetupGuide()
        .padding()
}
