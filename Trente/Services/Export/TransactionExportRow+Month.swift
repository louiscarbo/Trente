//
//  TransactionExportRow+Month.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import SwiftData

extension TransactionExportRow {
    init(entry: TransactionEntry, group: TransactionGroup, month: Month, hasImage: Bool = false) {
        self.init(
            date: group.addedDate,
            monthStartDate: month.startDate,
            title: group.title,
            type: group.type,
            category: entry.category,
            amountCents: entry.amountCents,
            currencyCode: month.currency.isoCode,
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
        months.flatMap { month in
            month.transactionGroups.flatMap { group in
                let hasImage = groupsWithImages.contains(group.persistentModelID)
                return group.entries.map { entry in
                    TransactionExportRow(entry: entry, group: group, month: month, hasImage: hasImage)
                }
            }
        }
    }

    static var groupsWithImagesDescriptor: FetchDescriptor<TransactionGroup> {
        var descriptor = FetchDescriptor<TransactionGroup>(predicate: #Predicate { group in group.imageAttachmentData != nil })
        descriptor.propertiesToFetch = [\.id]
        descriptor.relationshipKeyPathsForPrefetching = [\.month]
        return descriptor
    }

    static func groupsWithImagesDescriptor(inMonth monthID: UUID) -> FetchDescriptor<TransactionGroup> {
        var descriptor = FetchDescriptor<TransactionGroup>(
            predicate: #Predicate { group in group.month?.id == monthID && group.imageAttachmentData != nil }
        )
        descriptor.propertiesToFetch = [\.id]
        descriptor.fetchLimit = 1
        return descriptor
    }
}
