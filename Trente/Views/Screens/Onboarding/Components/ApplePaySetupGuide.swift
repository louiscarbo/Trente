//
//  ApplePaySetupGuide.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import SwiftUI

struct ApplePaySetupGuide: View {
    let steps: [LocalizedStringKey]

    var body: some View {
        VStack(spacing: .medium) {
            ShortcutsSetupCard(
                title: "In the Shortcuts app",
                systemImage: "creditcard",
                steps: steps
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
    ApplePaySetupGuide(steps: ShortcutsSetupCard.applePaySetupSteps)
        .padding()
}
