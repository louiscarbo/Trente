//
//  OnboardingGateTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 26/10/2026.
//

import Testing
@testable import Trente

struct OnboardingGateTests {
    @Test("Months arriving from iCloud before the onboarding saves its own month welcome the user back")
    func foundICloudData() {
        #expect(OnboardingGate.hasFoundICloudData(watchesICloud: true, hasSavedOwnMonth: false, monthCount: 2))
    }

    @Test("No months yet means nothing was found")
    func nothingYet() {
        #expect(!OnboardingGate.hasFoundICloudData(watchesICloud: true, hasSavedOwnMonth: false, monthCount: 0))
    }

    @Test("Once the onboarding saved its own month, new months are not iCloud data to restore")
    func ownMonthSaved() {
        #expect(!OnboardingGate.hasFoundICloudData(watchesICloud: true, hasSavedOwnMonth: true, monthCount: 1))
    }

    @Test("A replayed onboarding or a local-only store never looks for iCloud data")
    func notWatching() {
        #expect(!OnboardingGate.hasFoundICloudData(watchesICloud: false, hasSavedOwnMonth: false, monthCount: 3))
    }
}
