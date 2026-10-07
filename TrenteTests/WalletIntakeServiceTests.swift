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

        func suggestCategory(for transaction: WalletTransaction) async throws -> BudgetCategory? {
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
        merchant: String = "Dia",
        name: String = "Dia",
        amount: String = "53,74 €",
        in context: ModelContext,
        now: Date = .now
    ) async throws -> PendingTransaction {
        try await service.intake(
            merchant: merchant,
            name: name,
            amount: amount,
            card: "Visa",
            in: context,
            now: now
        )
    }

    @Test("Stores the merchant as title, the suggested category and a negative amount")
    func storesSuggestion() async throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let service = makeService(suggester: StubSuggester(category: .needs))
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let pending = try await intake(service, merchant: "  Dia ", in: context, now: now)

        #expect(pending.title == "Dia")
        #expect(pending.category == .needs)
        #expect(pending.amountCents == -53_74)
        #expect(pending.date == now)
        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).count == 1)
    }

    @Test("Falls back to the transaction name when the merchant is empty")
    func fallsBackToName() async throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let service = makeService(suggester: StubSuggester(category: .wants))

        let pending = try await intake(service, merchant: " ", name: "Teika M Vending", in: context)

        #expect(pending.title == "Teika M Vending")
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

    @Test("Throws when there is no title to use")
    func missingTitle() async throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let service = makeService(suggester: StubSuggester(category: .needs))

        await #expect(throws: WalletIntakeError.missingTitle) {
            try await intake(service, merchant: "", name: " ", in: context)
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
