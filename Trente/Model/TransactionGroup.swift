//
//  Transaction.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData
import SwiftUI

extension SchemaV1 {
    @Model
    class TransactionGroup: Identifiable {
        #Index<TransactionGroup>([\.addedDate], [\.recurringOccurrenceDate], [\.id])

        var id: UUID = UUID()
        var addedDate: Date = Date.now
        var modifiedDate: Date?
        var title: String = ""
        var type: TransactionType = TransactionType.expense
        var month: Month?
        var recurringRule: RecurringTransactionRule?
        var recurringOccurrenceDate: Date?

        @Relationship(deleteRule: .cascade, inverse: \TransactionEntry.group)
        var storedEntries: [TransactionEntry]? = []

        // Trente+
        var note: String?
        @Attribute(.externalStorage) var imageAttachmentData: Data?

        init(
            title: String,
            type: TransactionType,
            month: Month,
            note: String?,
            imageAttachmentData: Data?,
            addedDate: Date = .now
        ) {
            self.id = UUID()
            self.addedDate = addedDate
            self.modifiedDate = addedDate
            self.title = title
            self.type = type
            self.month = month
            self.storedEntries = []
            self.note = note
            self.imageAttachmentData = imageAttachmentData
        }
    }
}

enum TransactionType: String, Codable {
    case expense
    case income
}

// MARK: - Computed Properties
extension TransactionGroup {
    var entries: [TransactionEntry] {
        get { storedEntries ?? [] }
        set { storedEntries = newValue }
    }

    var currency: Currency {
        month?.currency ?? Currency.fallback
    }

    /// The total amount of all entries in cents. Can be negative or positive.
    var totalAmountCents: Int {
        entries.reduce(0) { $0 + $1.amountCents }
    }

    var totalAmount: Double {
        Double(totalAmountCents) / 100.0
    }

    /// Returns a localized string that displays the amount correctly, not in cents.
    var displayAmount: String {
        totalAmount
            .formatted(.currency(code: currency.isoCode))
    }
}
