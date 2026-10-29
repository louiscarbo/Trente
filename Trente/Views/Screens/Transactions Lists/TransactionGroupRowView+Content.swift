//
//  TransactionGroupRowView+Content.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

extension TransactionGroupRowView {
    struct Content: View {
        let title: String
        let entries: [(category: BudgetCategory, amount: Double)]
        let totalAmount: Double
        let currencyCode: String
        var isInList = false
        let onOpen: () -> Void

        var body: some View {
            if entries.count > 1 {
                groupDisclosure
            } else if let entry = entries.first {
                EntryRow(
                    category: entry.category,
                    amount: entry.amount,
                    currencyCode: currencyCode,
                    title: title,
                    onTap: onOpen
                )
            }
        }

        private var groupDisclosure: some View {
            DisclosureGroup {
                VStack {
                    if !isInList {
                        Divider()
                    }
                    ForEach(entries.indices, id: \.self) { index in
                        EntryRow(
                            category: entries[index].category,
                            amount: entries[index].amount,
                            currencyCode: currencyCode,
                            onTap: onOpen
                        )
                    }
                }
                .padding(.leading)
            } label: {
                TransactionGroupSummaryRow(
                    title: title,
                    amount: totalAmount,
                    currencyCode: currencyCode
                )
            }
        }
    }
}

#Preview {
    VStack {
        TransactionGroupRowView.Content(
            title: "Groceries",
            entries: [(category: .needs, amount: -54.20)],
            totalAmount: -54.20,
            currencyCode: "EUR"
        ) {}
        Divider()
        TransactionGroupRowView.Content(
            title: "Salary",
            entries: [
                (category: .needs, amount: 1_200),
                (category: .wants, amount: 600),
                (category: .savingsAndDebts, amount: 400)
            ],
            totalAmount: 2_200,
            currencyCode: "EUR"
        ) {}
    }
    .padding()
}
