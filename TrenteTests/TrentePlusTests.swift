//
//  TrentePlusTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import StoreKit
@testable import Trente

struct TrentePlusTests {

    @Test(
        "Only a subscription that is active or in its grace period unlocks Trente+",
        arguments: [
            ([], false),
            ([.expired], false),
            ([.revoked], false),
            ([.inBillingRetryPeriod], false),
            ([.subscribed], true),
            ([.inGracePeriod], true),
            ([.expired, .inGracePeriod], true)
        ] as [([Product.SubscriptionInfo.RenewalState], Bool)]
    )
    func isActive(states: [Product.SubscriptionInfo.RenewalState], expected: Bool) {
        #expect(TrentePlus.isActive(states) == expected)
    }

    #if DEBUG
    @Test(
        "The debug override replaces the App Store status only when one is picked",
        arguments: [
            (TrentePlusDebugOverride.appStore, false, false),
            (.appStore, true, true),
            (.subscribed, false, true),
            (.notSubscribed, true, false)
        ]
    )
    func debugOverride(override: TrentePlusDebugOverride, hasActiveSubscription: Bool, expected: Bool) {
        #expect(override.isSubscribed(hasActiveSubscription: hasActiveSubscription) == expected)
    }

    @Test("The debug override is remembered, and defaults to the App Store status")
    func debugOverrideStorage() throws {
        let defaults = try #require(UserDefaults(suiteName: "TrentePlusTests.\(UUID().uuidString)"))

        #expect(TrentePlusDebugOverride.stored(in: defaults) == .appStore)
        TrentePlusDebugOverride.notSubscribed.store(in: defaults)
        #expect(TrentePlusDebugOverride.stored(in: defaults) == .notSubscribed)
    }
    #endif
}
