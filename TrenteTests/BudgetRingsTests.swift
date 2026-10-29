//
//  BudgetRingsTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct BudgetRingsTests {
    private let income: [BudgetCategory: Double] = [.needs: 1500, .wants: 900, .savingsAndDebts: 600]

    private func rings(needs: Double, wants: Double, savings: Double) -> BudgetRings {
        BudgetRings(spent: [.needs: needs, .wants: wants, .savingsAndDebts: savings], income: income)
    }

    private func share(of kind: BudgetRings.SliceKind, in slices: [BudgetRings.Slice]) -> Double {
        slices.first { $0.kind == kind }?.share ?? -1
    }

    private func total(of slices: [BudgetRings.Slice]) -> Double {
        slices.reduce(0) { $0 + $1.share }
    }

    @Test("The split view gives each category its share of what was spent")
    func splitSegments() {
        let segments = rings(needs: 1100, wants: 620, savings: 400).segments(in: .split)

        #expect(abs(share(of: .category(.needs), in: segments) - 1100.0 / 2120) < 0.0001)
        #expect(abs(share(of: .category(.wants), in: segments) - 620.0 / 2120) < 0.0001)
        #expect(share(of: .remaining, in: segments) == 0)
        #expect(share(of: .overspent, in: segments) == 0)
        #expect(abs(total(of: segments) - 1) < 0.0001)
    }

    @Test("The plan ring follows how income is split between categories")
    func splitPlan() {
        let plan = rings(needs: 1100, wants: 620, savings: 400).plan(in: .split)

        #expect(share(of: .category(.needs), in: plan) == 0.5)
        #expect(share(of: .category(.wants), in: plan) == 0.3)
        #expect(abs(share(of: .category(.savingsAndDebts), in: plan) - 0.2) < 0.0001)
    }

    @Test("Left to spend measures spending against income and adds what remains")
    func leftToSpendUnderIncome() {
        let budget = rings(needs: 1100, wants: 620, savings: 400)
        let segments = budget.segments(in: .leftToSpend)
        let plan = budget.plan(in: .leftToSpend)

        #expect(abs(share(of: .category(.needs), in: segments) - 1100.0 / 3000) < 0.0001)
        #expect(abs(share(of: .remaining, in: segments) - 880.0 / 3000) < 0.0001)
        #expect(share(of: .overspent, in: segments) == 0)
        #expect(abs(total(of: segments) - 1) < 0.0001)
        #expect(abs(share(of: .remaining, in: plan) - 880.0 / 3000) < 0.0001)
        #expect(abs(total(of: plan) - 1) < 0.0001)
    }

    @Test("Past income, the overspending gets its own slice and never splits a category")
    func leftToSpendPastIncome() {
        let budget = rings(needs: 1600, wants: 1200, savings: 500)
        let segments = budget.segments(in: .leftToSpend)

        #expect(abs(share(of: .overspent, in: segments) - 300.0 / 3300) < 0.0001)
        #expect(share(of: .remaining, in: segments) == 0)
        #expect(abs(share(of: .category(.needs), in: segments) - 1600.0 / 3300 * 3000 / 3300) < 0.0001)
        #expect(abs(total(of: segments) - 1) < 0.0001)
        #expect(segments.filter { $0.kind == .category(.needs) }.count == 1)
    }

    @Test("The centre shows the share of income spent, left or spent past it")
    func centerShare() {
        #expect(abs((rings(needs: 1100, wants: 620, savings: 400).centerShare(in: .split) ?? 0) - 2120.0 / 3000) < 0.0001)
        #expect(abs((rings(needs: 1100, wants: 620, savings: 400).centerShare(in: .leftToSpend) ?? 0) - 880.0 / 3000) < 0.0001)
        #expect(abs((rings(needs: 1600, wants: 1200, savings: 500).centerShare(in: .leftToSpend) ?? 0) - 0.1) < 0.0001)
        #expect(BudgetRings(spent: [.needs: 10], income: [:]).centerShare(in: .split) == nil)
    }

    @Test("An empty month has no spending and cannot switch")
    func emptyMonth() {
        let budget = rings(needs: 0, wants: 0, savings: 0)

        #expect(!budget.hasSpending)
        #expect(total(of: budget.segments(in: .split)) == 0)
        #expect(budget.centerShare(in: .split) == 0)
    }

    @Test("Reads spending and income per category from the month")
    func readsMonth() {
        let month = Month(
            startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))!,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 3000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )
        let salary = TransactionGroup(title: "Salary", type: .income, month: month, note: nil, imageAttachmentData: nil, addedDate: month.startDate)
        salary.entries = [
            TransactionEntry(amountCents: 1500_00, category: .needs, group: salary),
            TransactionEntry(amountCents: 900_00, category: .wants, group: salary),
            TransactionEntry(amountCents: 600_00, category: .savingsAndDebts, group: salary)
        ]
        let groceries = TransactionGroup(title: "Groceries", type: .expense, month: month, note: nil, imageAttachmentData: nil, addedDate: month.startDate)
        groceries.entries = [TransactionEntry(amountCents: -120_50, category: .needs, group: groceries)]
        month.transactionGroups = [salary, groceries]

        let budget = BudgetRings(month: month)

        #expect(budget.totalIncome == 3000)
        #expect(budget.spent[.needs] == 120.5)
        #expect(budget.spent[.wants] == 0)
        #expect(budget.income[.wants] == 900)
    }
}
