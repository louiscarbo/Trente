//
//  TransactionListView+NoMatches.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

extension TransactionListView {
    struct NoMatches: View {
        let onReset: () -> Void

        var body: some View {
            ContentUnavailableView {
                Label("No Matching Transactions", systemImage: "line.horizontal.3.decrease.circle")
            } description: {
                Text("No transactions match these filters.")
            } actions: {
                Button("Reset Filters", action: onReset)
            }
        }
    }
}

#Preview {
    TransactionListView.NoMatches {}
}
