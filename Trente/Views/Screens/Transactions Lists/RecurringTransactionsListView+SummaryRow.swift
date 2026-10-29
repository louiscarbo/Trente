//
//  RecurringTransactionsListView+SummaryRow.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI
import SwiftData

extension RecurringTransactionsListView {
    struct SummaryRow: View {
        let title: String
        let schedule: String
        let amount: String
        let isEnded: Bool

        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(schedule)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(amount)
                    .font(.title3)
            }
            .opacity(isEnded ? 0.5 : 1)
        }
    }
}
