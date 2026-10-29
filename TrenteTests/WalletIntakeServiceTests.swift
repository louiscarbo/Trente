//
//  WalletIntakeServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@MainActor
@Suite(.serialized)
struct WalletIntakeServiceTests {

    private func makeAllowance() -> WalletIntakeAllowance {
        WalletIntakeAllowance(defaults: UserDefaults(suiteName: "WalletIntakeServiceTests.\(UUID().uuidString)")!)
    }

    @discardableResult
    private func intake(
        transaction: String = "Dia",
        amount: String = "53,74 €",
        in context: ModelContext,
        now: Date = .now,
        isTrentePlusSubscribed: Bool = false,
        allowance: WalletIntakeAllowance? = nil
    ) throws -> WalletIntakeResult {
        try WalletIntakeService(allowance: allowance ?? makeAllowance()).intake(
            transaction: transaction,
            amount: amount,
            in: context,
            now: now,
            isTrentePlusSubscribed: isTrentePlusSubscribed
        )
    }

    private func loggedPending(_ result: WalletIntakeResult) -> PendingTransaction? {
        if case .logged(let pending) = result { pending } else { nil }
    }

    @Test("Stores the transaction as title and a negative amount")
    func storesPending() throws {
        let context = try makeContext()
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let pending = try #require(loggedPending(try intake(transaction: "  Dia ", in: context, now: now)))

        #expect(pending.title == "Dia")
        #expect(pending.amountCents == -53_74)
        #expect(pending.date == now)
        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).count == 1)
    }

    @Test("Throws when the amount cannot be read")
    func unreadableAmount() throws {
        let context = try makeContext()

        #expect(throws: WalletIntakeError.unreadableAmount) {
            try intake(amount: "n/a", in: context)
        }
        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).isEmpty)
    }

    @Test("Throws when the transaction is blank")
    func missingTitle() throws {
        let context = try makeContext()

        #expect(throws: WalletIntakeError.missingTitle) {
            try intake(transaction: " ", in: context)
        }
    }

    @Test("Each logged purchase counts toward this month's free Apple Pay logs")
    func countsLoggedPurchases() throws {
        let context = try makeContext()
        let allowance = makeAllowance()

        try intake(in: context, allowance: allowance)
        try intake(in: context, allowance: allowance)

        #expect(allowance.count(on: .now) == 2)
    }

    @Test("Unreadable purchases don't count toward the free Apple Pay logs")
    func failedIntakeIsNotCounted() throws {
        let context = try makeContext()
        let allowance = makeAllowance()

        _ = try? intake(amount: "n/a", in: context, allowance: allowance)

        #expect(allowance.count(on: .now) == 0)
    }

    @Test("Past the free monthly limit, the purchase is not logged")
    func limitReached() throws {
        let context = try makeContext()
        let allowance = makeAllowance()
        allowance.setCount(WalletIntakeAllowance.freeMonthlyLimit, on: .now)

        let result = try intake(in: context, allowance: allowance)

        guard case .limitReached = result else {
            Issue.record("Expected the limit to be reached, got \(result)")
            return
        }
        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).isEmpty)
        #expect(allowance.count(on: .now) == WalletIntakeAllowance.freeMonthlyLimit)
    }

    @Test("Trente+ logs purchases past the free monthly limit")
    func trentePlusBypassesLimit() throws {
        let context = try makeContext()
        let allowance = makeAllowance()
        allowance.setCount(WalletIntakeAllowance.freeMonthlyLimit, on: .now)

        let result = try intake(in: context, isTrentePlusSubscribed: true, allowance: allowance)

        #expect(loggedPending(result) != nil)
        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).count == 1)
    }

    @Test("Starts the months missing up to today before picking the current one")
    func currentMonthStartsMissingMonths() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 9, in: context)
        let today = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 2))!

        let month = try WalletIntakeService().currentMonth(in: context, now: today)

        #expect(month.startDate == Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        #expect(try context.fetch(FetchDescriptor<Month>()).count == 3)
    }

    @Test("Throws when there is no month yet")
    func currentMonthWithoutMonths() throws {
        let context = try makeContext()

        #expect(throws: WalletIntakeError.noMonth) {
            try WalletIntakeService().currentMonth(in: context)
        }
    }
}
