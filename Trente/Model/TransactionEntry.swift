//
//  TransactionEntry.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 19/04/2025.
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    class TransactionEntry {
        var amountCents: Int = 0
        var category: BudgetCategory = BudgetCategory.needs

        @Relationship var group: TransactionGroup?

        init(amountCents: Int, category: BudgetCategory, group: TransactionGroup) {
            self.amountCents = amountCents
            self.category = category
            self.group = group
        }
    }
}

// MARK: Computed Properties
extension TransactionEntry {
    /// The amount, not in cents. Can be negative or positive.
    var amount: Double {
        Double(amountCents) / 100.0
    }

    /// Returns a localized string that displays the amount correctly, not in cents.
    var displayAmount: String {
        amount.formatted(.currency(code: (group?.currency ?? Currency.fallback).isoCode))
    }
}
