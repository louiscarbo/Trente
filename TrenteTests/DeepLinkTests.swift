//
//  DeepLinkTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct DeepLinkTests {
    static let monthID = UUID(uuidString: "6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B")!

    @Test(
        "Parses the links the widget opens",
        arguments: [
            ("trente://newtransaction/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B", DeepLink.newTransaction(monthID: DeepLinkTests.monthID)),
            ("trente://month/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B", DeepLink.month(id: DeepLinkTests.monthID)),
            ("TRENTE://NewTransaction/6f1c2a4e-8b3d-4e5f-9a7b-1c2d3e4f5a6b", DeepLink.newTransaction(monthID: DeepLinkTests.monthID)),
            ("trente://month/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B/", DeepLink.month(id: DeepLinkTests.monthID))
        ]
    )
    func parsesLink(text: String, expected: DeepLink) throws {
        let url = try #require(URL(string: text))

        #expect(DeepLink(url: url) == expected)
    }

    @Test(
        "Rejects malformed links",
        arguments: [
            "https://newtransaction/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B",
            "trente://newtransaction",
            "trente://newtransaction/not-a-uuid",
            "trente://newtransaction/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B/extra",
            "trente://unknown/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B",
            "trente:newtransaction/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B"
        ]
    )
    func rejectsLink(text: String) throws {
        let url = try #require(URL(string: text))

        #expect(DeepLink(url: url) == nil)
    }

    @Test("A link's URL parses back to the same link", arguments: [
        DeepLink.month(id: DeepLinkTests.monthID),
        DeepLink.newTransaction(monthID: DeepLinkTests.monthID)
    ])
    func roundTrip(link: DeepLink) {
        #expect(DeepLink(url: link.url) == link)
    }

    @Test("The widget's new transaction URL format still parses")
    func widgetFormat() throws {
        let url = try #require(URL(string: "trente://newtransaction/" + Self.monthID.uuidString))

        #expect(DeepLink(url: url) == .newTransaction(monthID: Self.monthID))
    }

    @MainActor
    @Test("A known month opens that month, with the new transaction sheet only for new transaction links")
    func knownMonth() throws {
        let latest = makeMonth(daysAgo: 0)
        let older = makeMonth(daysAgo: 40)

        let newTransaction = try #require(DeepLink.newTransaction(monthID: older.id).destination(in: [latest, older]))
        #expect(newTransaction.month === older)
        #expect(newTransaction.opensNewTransaction)

        let month = try #require(DeepLink.month(id: older.id).destination(in: [latest, older]))
        #expect(month.month === older)
        #expect(!month.opensNewTransaction)
    }

    @MainActor
    @Test("An unknown month falls back to the latest month without the sheet")
    func unknownMonth() throws {
        let latest = makeMonth(daysAgo: 0)
        let older = makeMonth(daysAgo: 40)

        let destination = try #require(DeepLink.newTransaction(monthID: UUID()).destination(in: [latest, older]))

        #expect(destination.month === latest)
        #expect(!destination.opensNewTransaction)
    }

    @MainActor
    @Test("No months means nowhere to go")
    func noMonths() {
        #expect(DeepLink.newTransaction(monthID: Self.monthID).destination(in: []) == nil)
    }

    private func makeMonth(daysAgo: Int) -> Month {
        Month(
            startDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )
    }
}
