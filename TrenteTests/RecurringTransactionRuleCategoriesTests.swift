//
//  RecurringTransactionRuleCategoriesTests.swift
//  TrenteTests
//

import Testing
import Foundation
@testable import Trente

struct RecurringTransactionRuleCategoriesTests {
    private func rule(_ repartition: [BudgetCategory: Int]) -> RecurringTransactionRule {
        RecurringTransactionRule(
            title: "Rule",
            frequency: .monthly,
            startDate: .now,
            repartition: repartition
        )
    }

    @Test("An expense has its one category")
    func expenseHasItsCategory() {
        #expect(rule([.wants: -12_00]).categories == [.wants])
    }

    @Test("An income has the categories it gives money to, in category order")
    func incomeHasItsCategoriesInOrder() {
        let income = rule([.savingsAndDebts: 300_00, .needs: 700_00])

        #expect(income.categories == [.needs, .savingsAndDebts])
    }

    @Test("A category left at zero after an edit is left out")
    func zeroShareIsLeftOut() {
        let income = rule([.needs: 1_000_00, .wants: 0, .savingsAndDebts: 0])

        #expect(income.categories == [.needs])
    }
}
