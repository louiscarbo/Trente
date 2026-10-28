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

        var body: some View {
            switch item.kind {
            case .group(let group):
                TransactionGroupRowView(transactionGroup: group, isInList: true)
            case .recurring(let occurrence):
                RecurringTransactionRowView(occurrence: occurrence)
            }
        }
    }
}
