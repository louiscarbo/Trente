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
        rule.repartition.values.reduce(0, +)
    }

    var displayAmount: String {
        (Double(amountCents) / 100.0).formatted(.currency(code: month.currency.isoCode))
    }

    var displayDate: String {
        date.formatted(.dateTime.weekday().day().month(.wide).year())
    }
}
