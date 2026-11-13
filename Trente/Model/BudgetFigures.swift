//
//  BudgetFigures.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Foundation

enum BudgetScope: Hashable {
    case all
    case category(BudgetCategory)
}

struct BudgetFigures: Hashable, Sendable {
    let spent: Double
    let income: Double
    let remaining: Double

    var isOverspent: Bool {
        remaining < 0
    }

    func isOverBudget(in scope: BudgetScope) -> Bool {
        isOverspent && !scope.isSavings
    }

    func extraSaved(in scope: BudgetScope) -> Double {
        scope.isSavings ? max(0, -remaining) : 0
    }
}

extension BudgetFigures {
    func gaugeIndicator(in scope: BudgetScope) -> Double {
        guard income > 0 else { return 0 }
        guard extraSaved(in: scope) == 0 else { return 1 }
        return min(max(remaining / income, 0), 1)
    }

    func gaugeHighlight(showingRemaining: Bool, in scope: BudgetScope) -> ClosedRange<Double> {
        let indicator = gaugeIndicator(in: scope)
        guard extraSaved(in: scope) == 0 else { return 0...1 }
        if showingRemaining {
            return 0...indicator
        }
        return spent > 0 ? indicator...1 : indicator...indicator
    }
}

extension BudgetScope {
    var isSavings: Bool {
        self == .category(.savingsAndDebts)
    }
}
