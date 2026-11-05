//
//  BudgetFiguresTests.swift
//  TrenteTests
//

import Testing
@testable import Trente

struct BudgetFiguresTests {
    private let overflowing = BudgetFigures(spent: 450, income: 300, remaining: -150)

    @Test("Saving more than planned isn't over budget")
    func savingsOverflowIsNotOverBudget() {
        #expect(!overflowing.isOverBudget(in: .category(.savingsAndDebts)))
        #expect(overflowing.extraSaved(in: .category(.savingsAndDebts)) == 150)
    }

    @Test("Spending more than planned elsewhere is over budget", arguments: [
        BudgetScope.all,
        .category(.needs),
        .category(.wants)
    ])
    func otherOverflowIsOverBudget(scope: BudgetScope) {
        #expect(overflowing.isOverBudget(in: scope))
        #expect(overflowing.extraSaved(in: scope) == 0)
    }

    @Test("Savings under the target have nothing extra")
    func savingsUnderTargetHaveNoExtra() {
        let figures = BudgetFigures(spent: 100, income: 300, remaining: 200)

        #expect(figures.extraSaved(in: .category(.savingsAndDebts)) == 0)
    }
}
