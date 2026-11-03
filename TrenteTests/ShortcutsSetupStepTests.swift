//
//  ShortcutsSetupStepTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import Testing
import Foundation
import FoundationModels
#if os(iOS)
import UIKit
#endif
@testable import Trente

@MainActor
struct ShortcutsSetupStepTests {

    #if os(iOS)
    @Test("Every step of the Wallet automation guide has its iPhone screenshot")
    func everyStepHasItsImage() {
        for imageName in ShortcutsSetupStep.walletAutomation.compactMap(\.imageName) {
            #expect(UIImage(named: imageName) != nil, "Missing \(imageName)")
        }
    }
    #endif

    @Test("Without Apple Intelligence the guide goes from the intro to Automation")
    func withoutAppleIntelligence() {
        let steps = ShortcutsSetupStep.walletAutomation(hasAppleIntelligence: false)
        #expect(steps.count == ShortcutsSetupStep.walletAutomation.count - 1)
        #expect(steps.first?.imageName == nil)
        #expect(steps[1].imageName == "Shortcuts Setup Automations")
    }

    @Test("With Apple Intelligence the guide goes from the intro to Edit")
    func withAppleIntelligence() {
        let steps = ShortcutsSetupStep.walletAutomation(hasAppleIntelligence: true)
        #expect(steps.count == ShortcutsSetupStep.walletAutomation.count)
        #expect(steps.first?.imageName == nil)
        #expect(steps[1].imageName == "Shortcuts Setup Edit")
    }

    @Test(
        "Shortcuts opens on the Describe screen only once Apple Intelligence is ready",
        arguments: [
            (SystemLanguageModel.Availability.available, true),
            (.unavailable(.modelNotReady), false),
            (.unavailable(.appleIntelligenceNotEnabled), false),
            (.unavailable(.deviceNotEligible), false)
        ]
    )
    func describeScreen(availability: SystemLanguageModel.Availability, opensOnDescribeScreen: Bool) {
        #expect(ShortcutsSetupStep.opensOnDescribeScreen(availability) == opensOnDescribeScreen)
    }
}
