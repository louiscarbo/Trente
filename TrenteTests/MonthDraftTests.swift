//
//  MonthDraftTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 31/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct MonthDraftTests {
    private let split: [BudgetCategory: Int] = [.needs: 500_00, .wants: 300_00, .savingsAndDebts: 200_00]

    private var draft: MonthDraft {
        MonthDraft(
            startDate: .distantPast,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 1000_00,
            idealRepartition: split
        )
    }

    @Test("Lowering the budget clears the split")
    func loweringClearsTheSplit() {
        var lowered = draft

        lowered.changeIdealBudget(to: 900_00)

        #expect(lowered.idealBudgetCents == 900_00)
        #expect(BudgetCategory.allCases.allSatisfy { lowered.idealRepartition[$0] == 0 })
    }

    @Test("Raising the budget keeps the split")
    func raisingKeepsTheSplit() {
        var raised = draft

        raised.changeIdealBudget(to: 1500_00)

        #expect(raised.idealBudgetCents == 1500_00)
        #expect(raised.idealRepartition == split)
    }

    @Test("Writing back the same budget keeps the split")
    func sameBudgetKeepsTheSplit() {
        var unchanged = draft

        unchanged.changeIdealBudget(to: 1000_00)

        #expect(unchanged == draft)
    }
}
