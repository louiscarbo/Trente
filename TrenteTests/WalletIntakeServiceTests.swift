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

    private struct StubSuggester: TransactionSuggesting {
        var category: BudgetCategory?
        var error: Error?
        var delay: Duration = .zero

        func suggestCategory(for transaction: String) async throws -> BudgetCategory? {
            try await Task.sleep(for: delay)
            if let error { throw error }
            return category
        }
    }

    private struct StubError: Error {}

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

    private func makeService(suggester: StubSuggester, timeout: Duration = .seconds(5)) -> WalletIntakeService {
        WalletIntakeService(suggester: suggester, suggestionTimeout: timeout)
    }

    private func intake(
        _ service: WalletIntakeService,
        transaction: String = "Dia",
        amount: String = "53,74 €",
        in context: ModelContext,
        now: Date = .now
    ) async throws -> PendingTransaction {
        try await service.intake(
            transaction: transaction,
            amount: amount,
            in: context,
            now: now
        )
    }

    @Test("Stores the transaction as title, the suggested category and a negative amount")
    func storesSuggestion() async throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let service = makeService(suggester: StubSuggester(category: .needs))
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let pending = try await intake(service, transaction: "  Dia ", in: context, now: now)

        #expect(pending.title == "Dia")
        #expect(pending.category == .needs)
        #expect(pending.amountCents == -53_74)
        #expect(pending.date == now)
        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).count == 1)
    }

    @Test("Leaves the category empty when the suggester fails")
    func suggesterFailure() async throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let service = makeService(suggester: StubSuggester(error: StubError()))

        let pending = try await intake(service, in: context)

        #expect(pending.category == nil)
    }

    @Test("Leaves the category empty when the suggester times out")
    func suggesterTimeout() async throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let service = makeService(
            suggester: StubSuggester(category: .needs, delay: .seconds(30)),
            timeout: .milliseconds(50)
        )

        let pending = try await intake(service, in: context)

        #expect(pending.category == nil)
    }

    @Test("Throws when the amount cannot be read")
    func unreadableAmount() async throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let service = makeService(suggester: StubSuggester(category: .needs))

        await #expect(throws: WalletIntakeError.unreadableAmount) {
            try await intake(service, amount: "n/a", in: context)
        }
        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).isEmpty)
    }

    @Test("Throws when no month exists")
    func noMonth() async throws {
        let context = try makeContext()
        let service = makeService(suggester: StubSuggester(category: .needs))

        await #expect(throws: WalletIntakeError.noMonth) {
            try await intake(service, in: context)
        }
    }

    @Test("Throws when the transaction is blank")
    func missingTitle() async throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let service = makeService(suggester: StubSuggester(category: .needs))

        await #expect(throws: WalletIntakeError.missingTitle) {
            try await intake(service, transaction: " ", in: context)
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
