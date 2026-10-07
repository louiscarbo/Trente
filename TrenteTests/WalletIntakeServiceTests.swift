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

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: .trente, configurations: config)
        return ModelContext(container)
    }

    @discardableResult
    private func insertMonth(year: Int, month: Int, in context: ModelContext) -> Month {
        let eur = Currencies.currency(for: "EUR")!
        let month = Month(
            startDate: Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!,
            currency: eur,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )
        context.insert(month)
        return month
    }

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

    @Test("The latest month by start date is the current one")
    func latestMonth() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 8, in: context)
        let latest = insertMonth(year: 2026, month: 10, in: context)
        insertMonth(year: 2026, month: 9, in: context)

        let found = try MonthService.shared.latestMonth(in: context)

        #expect(found?.id == latest.id)
    }
}
