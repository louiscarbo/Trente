//
//  TransactionGroupDraftTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Testing
@testable import Trente
import Foundation

struct TransactionGroupDraftTests {
    private func makeMonth() -> Month {
        Month(
            startDate: .now,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )
    }

    private func makeExpense(amountCents: Int, category: BudgetCategory) -> TransactionGroup {
        let group = TransactionGroup(title: "Groceries", type: .expense, month: makeMonth(), note: nil, imageAttachmentData: nil)
        group.entries = [TransactionEntry(amountCents: amountCents, category: category, group: group)]
        return group
    }

    private func makeIncome(repartition: [BudgetCategory: Int]) -> TransactionGroup {
        let group = TransactionGroup(title: "Salary", type: .income, month: makeMonth(), note: nil, imageAttachmentData: nil)
        group.entries = repartition.map { category, amountCents in
            TransactionEntry(amountCents: amountCents, category: category, group: group)
        }
        return group
    }

    @Test("A positive expense amount is stored as a negative amount")
    func positiveExpenseAmountBecomesNegative() {
        var draft = TransactionGroupDraft(from: makeExpense(amountCents: -12_00, category: .needs))

        draft.expenseAmountCents = 45_50

        #expect(draft.expenseAmountCents == -45_50)
    }

    @Test("A negative or missing expense amount is kept as is")
    func negativeExpenseAmountIsKept() {
        var draft = TransactionGroupDraft(from: makeExpense(amountCents: -12_00, category: .needs))

        draft.expenseAmountCents = -8_00
        #expect(draft.expenseAmountCents == -8_00)

        draft.expenseAmountCents = nil
        #expect(draft.expenseAmountCents == nil)
    }

    @Test("Changing the category of an expense keeps its amount")
    func categoryChangeKeepsExpenseAmount() {
        var draft = TransactionGroupDraft(from: makeExpense(amountCents: -12_00, category: .needs))

        draft.expenseCategory = .wants

        #expect(draft.expenseCategory == .wants)
        #expect(draft.expenseAmountCents == -12_00)
    }

    @Test("An income without an amount to split uses its repartition total")
    func missingAmountToSplitUsesRepartitionTotal() {
        var draft = TransactionGroupDraft(from: makeIncome(repartition: [.needs: 600_00]))
        draft.incomeAmountToSplitCents = 0
        draft.incomeRepartition = [.needs: 500_00, .wants: 300_00]

        draft.fillMissingAmountToSplit()

        #expect(draft.incomeAmountToSplitCents == 800_00)
        #expect(draft.validate().isEmpty)
    }

    @Test("An income with an amount to split keeps it")
    func existingAmountToSplitIsKept() {
        var draft = TransactionGroupDraft(from: makeIncome(repartition: [.needs: 600_00, .wants: 400_00]))

        draft.incomeRepartition = [.needs: 600_00]
        draft.fillMissingAmountToSplit()

        #expect(draft.incomeAmountToSplitCents == 1000_00)
    }

    @Test("Filling the amount to split leaves expenses untouched")
    func fillingAmountToSplitIgnoresExpenses() {
        var draft = TransactionGroupDraft(from: makeExpense(amountCents: -12_00, category: .needs))
        draft.incomeRepartition = [.needs: 50_00]

        draft.fillMissingAmountToSplit()

        #expect(draft.incomeAmountToSplitCents == 0)
    }
}
