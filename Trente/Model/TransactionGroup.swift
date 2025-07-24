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
    var note: String?
    @Attribute(.externalStorage) var imageAttachmentData: Data?
    
    init(title: String, type: TransactionType, month: Month, note: String?, imageAttachmentData: Data?) {
        self.id = UUID()
        self.addedDate = .now
        self.modifiedDate = .now
        self.title = title
        self.type = type
        self.month = month
        self.isDeleted = false
        self.entries = []
        self.note = note
        self.imageAttachmentData = imageAttachmentData
    }
    
    private init(copying original: TransactionGroup) {
        self.id = original.id
        self.addedDate = original.addedDate
        self.modifiedDate = original.modifiedDate
        self.title = original.title
        self.type = original.type
        self.month = original.month
        self.isDeleted = original.isDeleted
        self.note = original.note
        self.imageAttachmentData = original.imageAttachmentData
        // Create detached copies for the entries
        self.entries = original.entries.map { $0.detachedCopy() }
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

// TODO: Investigate if detachedCopy() is really needed
extension TransactionGroup {
    func detachedCopy() -> TransactionGroup {
        return TransactionGroup(copying: self)
    }
}
