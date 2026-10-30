//
//  BudgetIntentServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@MainActor
@Suite(.serialized)
struct BudgetIntentServiceTests {
    private let service = BudgetIntentService()
    private let now = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 12))!

    private func addIncome(_ cents: Int, to category: BudgetCategory, in month: Month, context: ModelContext) {
        let group = TransactionGroup(title: "Salary", type: .income, month: month, note: nil, imageAttachmentData: nil, addedDate: month.startDate)
        context.insert(group)
        context.insert(TransactionEntry(amountCents: cents, category: category, group: group))
    }

    private func insertAutomaticRule(in context: ModelContext) -> RecurringTransactionRule {
        let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 2))!
        let rule = RecurringTransactionRule(
            title: "Rent",
            frequency: .monthly,
            startDate: startDate,
            autoConfirm: true,
            repartition: [.needs: -800_00],
            createdAt: startDate
        )
        context.insert(rule)
        return rule
    }

    @Test(
        "Turns a spoken amount into positive cents",
        arguments: [
            (Decimal(12), 1200),
            (Decimal(string: "12.5")!, 1250),
            (Decimal(string: "0.01")!, 1),
            (Decimal(string: "12.345")!, 1235),
            (Decimal(string: "1999.99")!, 1999_99)
        ]
    )
    func cents(amount: Decimal, expected: Int) {
        #expect(BudgetIntentService.cents(from: amount) == expected)
    }

    @Test("Rejects amounts that are not more than zero", arguments: [Decimal(0), Decimal(-5), Decimal(string: "0.004")!])
    func invalidCents(amount: Decimal) {
        #expect(BudgetIntentService.cents(from: amount) == nil)
    }

    @Test("Uses the month that contains today, even when a later month exists")
    func monthContainingToday() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        insertMonth(year: 2026, month: 11, in: context)

        #expect(try service.currentMonth(in: context, now: now) == october)
    }

    @Test("Creates the missing months up to today, like the Wallet intake")
    func createsMissingMonths() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 8, in: context)

        let month = try service.currentMonth(in: context, now: now)

        #expect(month.contains(now))
        #expect(try context.fetchCount(FetchDescriptor<Month>()) == 3)
    }

    @Test("Throws when there is no month at all")
    func noMonth() throws {
        let context = try makeContext()

        #expect(throws: BudgetIntentError.noMonth) {
            try service.currentMonth(in: context, now: now)
        }
    }

    @Test("Saves the expense in today's month with the month's currency")
    func addsExpense() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        addIncome(500_00, to: .wants, in: month, context: context)

        let added = try service.addExpense(
            amount: Decimal(string: "12.5")!,
            title: "  Coffee ",
            category: .wants,
            in: context,
            now: now
        )

        let group = try #require(month.transactionGroups.first { $0.type == .expense })
        #expect(group.title == "Coffee")
        #expect(group.addedDate == now)
        #expect(group.entries.map(\.amountCents) == [-12_50])
        #expect(group.entries.map(\.category) == [.wants])
        #expect(added.amountCents == 12_50)
        #expect(added.remaining.scope == .category(.wants))
        #expect(added.remaining.figures.remaining == 487.5)
        #expect(added.remaining.currencyCode == "EUR")
    }

    @Test("Refuses a blank title or a zero amount without saving")
    func refusesInvalidExpense() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)

        #expect(throws: BudgetIntentError.missingTitle) {
            try service.addExpense(amount: 10, title: " ", category: .needs, in: context, now: now)
        }
        #expect(throws: BudgetIntentError.invalidAmount) {
            try service.addExpense(amount: 0, title: "Bread", category: .needs, in: context, now: now)
        }
        #expect(try context.fetchCount(FetchDescriptor<TransactionGroup>()) == 0)
    }

    @Test("Remaining is income minus spending, per category or in total")
    func remaining() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        addIncome(1000_00, to: .needs, in: month, context: context)
        addIncome(300_00, to: .wants, in: month, context: context)
        _ = try service.addExpense(amount: 400, title: "Rent", category: .needs, in: context, now: now)
        _ = try service.addExpense(amount: 350, title: "Concert", category: .wants, in: context, now: now)

        let needs = try service.remaining(in: .category(.needs), context: context, now: now)
        let wants = try service.remaining(in: .category(.wants), context: context, now: now)
        let total = try service.remaining(in: .all, context: context, now: now)

        #expect(needs.figures.remaining == 600)
        #expect(wants.figures.remaining == -50)
        #expect(wants.figures.isOverspent)
        #expect(total.figures.remaining == 550)
        #expect(total.monthName == month.name)
    }

    @Test("Remaining counts due automatic transactions without recording them")
    func remainingIncludesDueAutomaticTransactions() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        addIncome(1000_00, to: .needs, in: month, context: context)
        let rule = insertAutomaticRule(in: context)
        try context.save()

        let needs = try service.remaining(
            in: .category(.needs),
            context: context,
            now: now,
            isTrentePlusSubscribed: true
        )

        #expect(needs.figures.remaining == 200)
        #expect(rule.lastAutoConfirmedDate == nil)
        #expect(month.transactionGroups.count == 1)
    }

    @Test("Remaining leaves out automatic transactions without Trente+")
    func remainingSkipsAutomaticTransactionsWithoutTrentePlus() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        addIncome(1000_00, to: .needs, in: month, context: context)
        let rule = insertAutomaticRule(in: context)
        try context.save()

        let needs = try service.remaining(
            in: .category(.needs),
            context: context,
            now: now,
            isTrentePlusSubscribed: false
        )

        #expect(needs.figures.remaining == 1000)
        #expect(rule.lastAutoConfirmedDate == nil)
    }

    @Test("Category enum keeps the raw values stored in data and widget configurations")
    func categoryRawValues() {
        #expect(BudgetCategory.allCases.map(\.rawValue) == ["needs", "wants", "savingsAndDebts"])
        #expect(Set(BudgetCategory.caseDisplayRepresentations.keys) == Set(BudgetCategory.allCases))
    }
}
