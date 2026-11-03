//
//  TransactionListView+Row.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import SwiftUI

extension TransactionListView {
    struct Row: View {
        let item: DisplayableTransaction
        let isSelecting: Bool
        let onOpenOccurrence: (RecurringTransactionOccurrence) -> Void

        var body: some View {
            switch item.kind {
            case .group(let group) where isSelecting:
                TransactionGroupRowContent(
                    title: group.title,
                    categories: group.entries.map(\.category),
                    amount: group.totalAmount,
                    currencyCode: group.currency.isoCode
                )
            case .group(let group):
                TransactionGroupRowView(transactionGroup: group, isInList: true)
            case .recurring(let occurrence):
                RecurringTransactionRowView(occurrence: occurrence) {
                    onOpenOccurrence(occurrence)
                }
            }
        }
    }
}
