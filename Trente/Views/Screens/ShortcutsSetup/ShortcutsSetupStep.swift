//
//  ShortcutsSetupStep.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftUI

struct ShortcutsSetupStep {
    let instruction: LocalizedStringKey
    var imageName: String?
    var needsAppleIntelligence = false

    static func walletAutomation(hasAppleIntelligence: Bool) -> [ShortcutsSetupStep] {
        walletAutomation.filter { hasAppleIntelligence || !$0.needsAppleIntelligence }
    }

    static var walletAutomation: [ShortcutsSetupStep] {
        [
            ShortcutsSetupStep(
                instruction: "Trente will walk you through one automation in the Shortcuts app. Come back here after each step."
            ),
            ShortcutsSetupStep(
                instruction: "Tap **Edit** in the top right corner.",
                imageName: "Shortcuts Setup Edit",
                needsAppleIntelligence: true
            ),
            ShortcutsSetupStep(
                instruction: "Tap **Automation**.",
                imageName: "Shortcuts Setup Automations"
            ),
            ShortcutsSetupStep(
                instruction: "Scroll down and tap **Wallet**.",
                imageName: "Shortcuts Setup Wallet"
            ),
            ShortcutsSetupStep(
                instruction: "Tap **Search** at the bottom and type “Trente”.",
                imageName: "Shortcuts Setup Search"
            ),
            ShortcutsSetupStep(
                instruction: "Tap **Trente & Wallet**.",
                imageName: "Shortcuts Setup Action"
            ),
            ShortcutsSetupStep(
                instruction: "Tap the **Transaction** field. In the bar above the keyboard, scroll to the end and tap **Transaction**.",
                imageName: "Shortcuts Setup Transaction"
            ),
            ShortcutsSetupStep(
                instruction: "Tap the **Amount** field. Scroll the bar to the end again and tap **Transaction**.",
                imageName: "Shortcuts Setup Amount"
            ),
            ShortcutsSetupStep(
                instruction: "Tap the new **Transaction** in the Amount field, then choose **Amount**.",
                imageName: "Shortcuts Setup Amount Detail"
            ),
            ShortcutsSetupStep(
                instruction: "That's it! Trente will prepare an expense after each Apple Pay purchase.",
                imageName: "Shortcuts Setup Done"
            )
        ]
    }
}
