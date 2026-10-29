//
//  TransactionGroupRowView+EntryRow.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI

extension TransactionGroupRowView {
    struct EntryRow: View {
        let category: BudgetCategory
        let amount: Double
        let currencyCode: String
        var title: String?
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                TransactionEntryRowContent(
                    category: category,
                    amount: amount,
                    currencyCode: currencyCode,
                    title: title
                )
            }
            .contentShape(.rect)
            .buttonStyle(.plain)
        }
    }
}
