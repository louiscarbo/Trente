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

extension BudgetScope {
    var isSavings: Bool {
        self == .category(.savingsAndDebts)
    }
}
