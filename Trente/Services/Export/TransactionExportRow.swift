//
//  TransactionExportRow.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import SwiftData

struct TransactionExportRow: Hashable, Sendable {
    let date: Date
    let monthStartDate: Date
    let title: String
    let type: TransactionType
    let category: BudgetCategory
    let amountCents: Int
    let currencyCode: String
    let isRecurring: Bool
    let note: String?
    let transactionID: UUID
    var imageSourceID: PersistentIdentifier? = nil
}
