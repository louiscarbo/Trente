//
//  MonthView+LatestTransactions.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

extension MonthView {
    struct LatestTransactions<AllTransactions: View>: View {
        let transactions: [TransactionGroup]
        let transactionGroupsCount: Int
        var transactionCount: Int = 3
        @ViewBuilder let allTransactions: () -> AllTransactions

        var body: some View {
            let latestTransactions = Array(transactions.prefix(transactionCount))

            GroupBox(label: Label("Latest Transactions", systemImage: "clock.arrow.circlepath")) {
                ForEach(latestTransactions) { transaction in
                    TransactionGroupRowView(transactionGroup: transaction)

                    if transaction != latestTransactions.last {
                        Divider()
                    }
                }

                HStack {
                    if transactionGroupsCount == 0 {
                        Text("Add your first transaction by tapping 'Add Transaction'.")
                            .foregroundStyle(.secondary)
                    } else if latestTransactions.isEmpty {
                        Text("Add your first transaction for this month by tapping 'Add Transaction'.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                if transactionGroupsCount > 0 {
                    NavigationLink(destination: allTransactions) {
                        Text("See all transactions")
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle())
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
    }
}
