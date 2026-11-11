//
//  ShortcutsSetupSheet+StepPage.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftUI

extension ShortcutsSetupSheet {
    struct StepPage: View {
        let instruction: LocalizedStringKey
        let imageName: String?
        let showsPrivacyNote: Bool
        let onOpenShortcuts: (() -> Void)?

        var body: some View {
            ScrollView {
                VStack(spacing: .large) {
                    illustration

                    Text(instruction)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    if let onOpenShortcuts {
                        Button(action: onOpenShortcuts) {
                            Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                                .padding(.horizontal)
                        }
                        .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
                        .fixedSize()
                    }

                    if showsPrivacyNote {
                        Label(
                            "Trente only receives the merchant name and the amount. Never your card details.",
                            systemImage: "lock.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .scrollBounceBehavior(.basedOnSize)
        }

        @ViewBuilder
        private var illustration: some View {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: .large))
                    .overlay {
                        RoundedRectangle(cornerRadius: .large)
                            .strokeBorder(.separator)
                    }
                    .frame(maxHeight: 360)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "square.2.layers.3d")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, DesignSystem.Spacing.large.rawValue)
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview("Intro") {
    ShortcutsSetupSheet.StepPage(
        instruction: ShortcutsSetupStep.walletAutomation[0].instruction,
        imageName: nil,
        showsPrivacyNote: true,
        onOpenShortcuts: nil
    )
}

#Preview("Step") {
    ShortcutsSetupSheet.StepPage(
        instruction: ShortcutsSetupStep.walletAutomation[1].instruction,
        imageName: ShortcutsSetupStep.walletAutomation[1].imageName,
        showsPrivacyNote: false,
        onOpenShortcuts: {}
    )
}
