//
//  BudgetRings.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Foundation

struct BudgetRings: Hashable {
    enum Lens: Hashable {
        case split, leftToSpend
    }

    enum SliceKind: Hashable {
        case category(BudgetCategory)
        case remaining
        case overspent
    }

    struct Slice: Hashable, Identifiable {
        let kind: SliceKind
        let share: Double

        var id: SliceKind { kind }
    }

    let spent: [BudgetCategory: Double]
    let income: [BudgetCategory: Double]

    init(spent: [BudgetCategory: Double], income: [BudgetCategory: Double]) {
        self.spent = spent
        self.income = income
    }

    init(month: Month) {
        let categories = BudgetCategory.allCases
        self.init(
            spent: Dictionary(uniqueKeysWithValues: categories.map { ($0, month.spentAmount(for: $0)) }),
            income: Dictionary(uniqueKeysWithValues: categories.map { ($0, month.incomeAmount(for: $0)) })
        )
    }

    var totalSpent: Double {
        spent.values.reduce(0, +)
    }

    var totalIncome: Double {
        income.values.reduce(0, +)
    }

    var hasSpending: Bool {
        totalSpent > 0
    }

    var isOverspent: Bool {
        totalSpent > totalIncome
    }

    func segments(in lens: Lens) -> [Slice] {
        switch lens {
        case .split:
            let total = totalSpent
            return categorySlices { total > 0 ? spent[$0, default: 0] / total : 0 }
                + leftoverSlices(remaining: 0, overspent: 0)
        case .leftToSpend:
            let circle = max(totalIncome, totalSpent)
            guard circle > 0 else { return segments(in: .split) }
            let coveredShare = hasSpending ? min(totalIncome, totalSpent) / totalSpent / circle : 0
            return categorySlices { spent[$0, default: 0] * coveredShare }
                + leftoverSlices(
                    remaining: max(0, totalIncome - totalSpent) / circle,
                    overspent: max(0, totalSpent - totalIncome) / circle
                )
        }
    }

    func plan(in lens: Lens) -> [Slice] {
        let total = totalIncome
        let incomeShare: (BudgetCategory) -> Double = { total > 0 ? income[$0, default: 0] / total : 0 }
        switch lens {
        case .split:
            return categorySlices(incomeShare) + leftoverSlices(remaining: 0, overspent: 0)
        case .leftToSpend:
            let circle = max(totalIncome, totalSpent)
            guard circle > 0 else { return plan(in: .split) }
            let scale = min(totalIncome, totalSpent) / circle
            return categorySlices { incomeShare($0) * scale }
                + leftoverSlices(
                    remaining: totalIncome > totalSpent ? 1 - scale : 0,
                    overspent: totalSpent > totalIncome ? 1 - scale : 0
                )
        }
    }

    func centerShare(in lens: Lens) -> Double? {
        guard totalIncome > 0 else { return nil }
        switch lens {
        case .split: return totalSpent / totalIncome
        case .leftToSpend: return abs(totalIncome - totalSpent) / totalIncome
        }
    }

    private func categorySlices(_ share: (BudgetCategory) -> Double) -> [Slice] {
        BudgetCategory.allCases.map { Slice(kind: .category($0), share: share($0)) }
    }

    private func leftoverSlices(remaining: Double, overspent: Double) -> [Slice] {
        [Slice(kind: .remaining, share: remaining), Slice(kind: .overspent, share: overspent)]
    }
}
