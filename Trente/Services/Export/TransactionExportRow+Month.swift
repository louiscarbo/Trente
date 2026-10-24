//
//  TransactionExportRow+Month.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import SwiftData

extension TransactionExportRow {
    init(entry: TransactionEntry, hasImage: Bool = false) {
        let group = entry.group
        self.init(
            date: group.addedDate,
            monthStartDate: group.month.startDate,
            title: group.title,
            type: group.type,
            category: entry.category,
            amountCents: entry.amountCents,
            currencyCode: group.month.currency.isoCode,
            isRecurring: group.recurringOccurrenceDate != nil,
            note: group.note,
            transactionID: group.id,
            imageSourceID: hasImage ? group.persistentModelID : nil
        )
    }

    static func rows(
        from months: [Month],
        groupsWithImages: Set<PersistentIdentifier> = []
    ) -> [TransactionExportRow] {
        months
            .flatMap(\.transactionGroups)
            .flatMap(\.entries)
            .map { entry in
                TransactionExportRow(entry: entry, hasImage: groupsWithImages.contains(entry.group.persistentModelID))
            }
    }

    static var groupsWithImagesDescriptor: FetchDescriptor<TransactionGroup> {
        FetchDescriptor(predicate: #Predicate { group in group.imageAttachmentData != nil })
    }
}
