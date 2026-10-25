//
//  TransactionExportRow+Month.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation

extension TransactionExportRow {
    init(entry: TransactionEntry) {
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
            transactionID: group.id
        )
    }

    static func rows(from months: [Month]) -> [TransactionExportRow] {
        months
            .flatMap(\.transactionGroups)
            .flatMap(\.entries)
            .map(TransactionExportRow.init(entry:))
    }
}
