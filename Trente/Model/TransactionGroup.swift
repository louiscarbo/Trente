//
//  Transaction.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class TransactionGroup: Identifiable {
    var id: UUID = UUID()
    var addedDate: Date
    var modifiedDate: Date?
    var title: String
    var type: TransactionType
    var month: Month
    var isDeleted: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \TransactionEntry.group)
    var entries: [TransactionEntry] = []
    
    // Trente+
    var note: String? = nil
    @Attribute(.externalStorage) var imageAttachmentData: Data? = nil
    
    init(addedDate: Date, title: String, type: TransactionType, month: Month) {
        self.addedDate = addedDate
        self.title = title
        self.type = type
        self.month = month
    }
}

enum TransactionType: String, Codable {
    case expense
    case income
}

// MARK: - Computed Properties
extension TransactionGroup {
    /// The total amount of all entries in cents. Can be negative or positive.
    var totalAmountCents: Int {
        entries.reduce(0) { $0 + $1.amountCents }
    }
    
    /// Returns a localized string that displays the amount correctly, not in cents.
    var displayAmount: String {
        (Double(totalAmountCents) / 100.0)
            .formatted(.currency(code: month.currency.isoCode))
    }
}

extension TransactionGroup {
    func detachedCopy() -> TransactionGroup {
        let copy = TransactionGroup(
            addedDate: addedDate,
            title: title,
            type: type,
            month: month
        )
        
        copy.entries = entries.map { $0.detachedCopy() }
        return copy
    }
}
