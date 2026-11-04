//
//  PendingPurchasesCardTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import Testing
import Foundation
@testable import Trente

@MainActor
struct PendingPurchasesCardTests {

    private func card(titlesAndCents: [(String, Int)]) -> MonthView.PendingPurchases {
        MonthView.PendingPurchases(
            pendingTransactions: titlesAndCents.map { title, cents in
                PendingTransaction(date: .now, amountCents: cents, title: title)
            },
            currencyCode: "EUR",
            onReview: { _ in }
        )
    }

    @Test("Up to two purchases each get a row", arguments: [0, 1, 2])
    func smallCountsShowEveryRow(pendingCount: Int) {
        #expect(MonthView.PendingPurchases.rowCount(forPendingCount: pendingCount) == pendingCount)
    }

    @Test("From three purchases on, one row stays and the rest go behind the button", arguments: [3, 4, 25])
    func largeCountsShowOneRow(pendingCount: Int) {
        #expect(MonthView.PendingPurchases.rowCount(forPendingCount: pendingCount) == 1)
    }

    @Test("The button sums and names the purchases it hides, never the one on the card")
    func hiddenSummaryCoversHiddenPurchases() {
        let pendingCard = card(titlesAndCents: [("Café", -4_20), ("Monoprix", -38_17), ("Uber", -12_60)])

        #expect(pendingCard.hiddenAmount == -50.77)
        #expect(pendingCard.hiddenTitles == "Monoprix, Uber")
    }
}
