//
//  RecurringTransactionInstance.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class RecurringTransactionInstance {
    var date: Date
    var rule: RecurringTransactionRule
    var month: Month
    var transactionEntry: TransactionEntry? = nil
    
    init(date: Date, rule: RecurringTransactionRule, month: Month, confirmed: Bool) {
        self.date = date
        self.rule = rule
        self.month = month
    }
}

// MARK: - Computed Properties
extension RecurringTransactionInstance {
    var displayDate: String {
        return date.formatted(.dateTime.weekday().day().month(.wide).year())
    }
    
    var displayAmount: String {
        let amount = rule.amountCents
        return (Double(amount)/100.0).formatted(.currency(code: month.currency.isoCode))
    }
    
    var confirmed: Bool {
        transactionEntry != nil
    }
}
