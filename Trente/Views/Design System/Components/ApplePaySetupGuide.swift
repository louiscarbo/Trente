//
//  ApplePaySetupGuide.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import SwiftUI

struct ApplePaySetupGuide: View {
    static let steps: [LocalizedStringKey] = [
        "Tap **Get the Shortcut** below and add **Log Wallet Transaction** to your shortcuts.",
        "In the **Automation** tab, create a new automation with the **Wallet** trigger, choose your cards and select **Run Immediately**.",
        "Add **Run Shortcut**, pick **Log Wallet Transaction** and pass it the **Shortcut Input**."
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
