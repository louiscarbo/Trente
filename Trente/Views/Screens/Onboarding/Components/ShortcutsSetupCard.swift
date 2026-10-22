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
                    HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.medium.rawValue) {
                        Text(index + 1, format: .number)
                            .font(.subheadline)
                            .bold()
                            .frame(width: 26, height: 26)
                            .background(.primary.opacity(0.1), in: Circle())
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
        title: "Set up the automation",
        systemImage: "wallet.pass",
        steps: [
            "Open the Shortcuts app and go to Automation.",
            "Tap + and choose Wallet.",
            "Pick your cards, then choose Run Immediately.",
            "Add Run Shortcut and pick Log Wallet Transaction."
        ]
    )
    .padding()
}
