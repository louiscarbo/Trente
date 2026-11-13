//
//  BudgetCategory+ProportionalSplit.swift
//  Trente
//

import Foundation

extension BudgetCategory {
    static func proportionalSplit(of amountCents: Int, weights: [BudgetCategory: Int]) -> [BudgetCategory: Int] {
        let totalWeight = weights.values.reduce(0, +)
        guard amountCents > 0, totalWeight > 0 else {
            return Dictionary(uniqueKeysWithValues: allCases.map { ($0, 0) })
        }
        let needsCents = wholeUnitShare(of: amountCents, weight: weights[.needs, default: 0], totalWeight: totalWeight)
        let wantsCents = wholeUnitShare(of: amountCents, weight: weights[.wants, default: 0], totalWeight: totalWeight)
        return [
            .needs: needsCents,
            .wants: wantsCents,
            .savingsAndDebts: amountCents - needsCents - wantsCents
        ]
    }

    private static func wholeUnitShare(of amountCents: Int, weight: Int, totalWeight: Int) -> Int {
        let product = amountCents.multipliedFullWidth(by: max(weight, 0))
        let shareCents = totalWeight.dividingFullWidth(product).quotient
        return (shareCents / 100) * 100
    }
}
