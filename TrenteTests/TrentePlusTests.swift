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
}
