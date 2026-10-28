//
//  RecurringTransactionOccurrence.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/10/2026.
//

import Foundation
import SwiftData

struct RecurringTransactionOccurrence: Identifiable, Hashable {
    struct Key: Hashable {
        let rule: PersistentIdentifier
        let date: Date
    }

    let rule: RecurringTransactionRule
    let date: Date
    let month: Month

    var id: Key {
        Key(rule: rule.persistentModelID, date: date)
    }

    var amountCents: Int {
        rule.amountCents
    }

    func amountCents(in scope: BudgetScope) -> Int {
        switch scope {
        case .all: amountCents
        case .category(let category): rule.repartition[category] ?? 0
        }
    }

    var isIncome: Bool {
        amountCents > 0
    }

    var isOverdue: Bool {
        date < Calendar.current.startOfDay(for: .now)
    }

    var categoryName: String {
        if amountCents < 0, let category = rule.repartition.keys.first {
            return category.shortName
        }
        return String(localized: "Income")
    }
}
