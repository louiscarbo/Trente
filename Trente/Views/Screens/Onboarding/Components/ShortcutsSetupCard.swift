//
//  ShortcutsSetupCard.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct ShortcutsSetupCard: View {
    let title: LocalizedStringKey
    let systemImage: String
    let steps: [LocalizedStringKey]

    var body: some View {
        GroupBox(label: Label(title, systemImage: systemImage)) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium.rawValue) {
                ForEach(steps.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.medium.rawValue) {
                        Text(index + 1, format: .number)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.background)
                            .frame(width: 26, height: 26)
                            .background(.primary, in: Circle())
                            .accessibilityHidden(true)
                        Text(steps[index])
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

#Preview {
    ShortcutsSetupCard(
        title: "In the Shortcuts app",
        systemImage: "creditcard",
        steps: [
            "Tap **Get the Shortcut** below and add **Log Wallet Transaction** to your shortcuts.",
            "In the **Automation** tab, create a new automation with the **Wallet** trigger, choose your cards and select **Run Immediately**.",
            "Add **Run Shortcut**, pick **Log Wallet Transaction** and pass it the **Shortcut Input**."
        ]
    )
    .padding()
}
