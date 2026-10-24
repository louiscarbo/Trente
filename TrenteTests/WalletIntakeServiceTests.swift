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

    private func intake(
        transaction: String = "Dia",
        amount: String = "53,74 €",
        in context: ModelContext,
        now: Date = .now
    ) throws -> PendingTransaction {
        try WalletIntakeService().intake(
            transaction: transaction,
            amount: amount,
            in: context,
            now: now
        )
    }

    @Test("Stores the transaction as title and a negative amount")
    func storesPending() throws {
        let context = try makeContext()
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let pending = try intake(transaction: "  Dia ", in: context, now: now)

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
