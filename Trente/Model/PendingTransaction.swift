//
//  PendingTransaction.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Foundation
import SwiftData

@Model
class PendingTransaction: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var amountCents: Int
    var title: String
    var category: BudgetCategory?

    init(
        date: Date,
        amountCents: Int,
        title: String,
        category: BudgetCategory?
    ) {
        self.id = UUID()
        self.date = date
        self.amountCents = amountCents
        self.title = title
        self.category = category
    }
}
