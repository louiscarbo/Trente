//
//  TransactionGroupRowView+EntryRow.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftData
import SwiftUI

extension TransactionGroupRowView {
    struct EntryRow: View {
        let transactionGroup: TransactionGroup
        let transactionEntry: TransactionEntry
        var title: String?

        @State private var showTransactionGroupDetails: Bool = false

        var body: some View {
            Button {
                showTransactionGroupDetails = true
            } label: {
                TransactionEntryRowContent(
                    category: transactionEntry.category,
                    amount: transactionEntry.amount,
                    currencyCode: transactionGroup.currency.isoCode,
                    title: title
                )
            }
            .contentShape(.rect)
            .buttonStyle(.plain)
            .sheet(isPresented: $showTransactionGroupDetails) {
                TransactionGroupDetailsView(transactionGroup: transactionGroup)
            }
        }
    }
}
