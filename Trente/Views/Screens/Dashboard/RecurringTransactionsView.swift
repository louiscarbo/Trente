//
//  RecurringTransactionsView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

struct RecurringTransactionsView<AllOccurrences: View>: View {
    let upcomingOccurrences: [RecurringTransactionOccurrence]
    let recurringTransactionsCount: Int
    var transactionCount: Int = 3
    @ViewBuilder let allOccurrences: () -> AllOccurrences

    var body: some View {
        let shownOccurrences = Array(upcomingOccurrences.prefix(transactionCount))

        GroupBox(label: Label("Expected This Month", systemImage: "calendar.badge.clock")) {
            ForEach(shownOccurrences) { occurrence in
                RecurringTransactionRowView(occurrence: occurrence)
                
                if occurrence != shownOccurrences.last {
                    Divider()
                }
            }
            
            HStack {
                if recurringTransactionsCount == 0 {
                    Text("Add your first Recurring Transaction by tapping 'Add Transaction'.")
                        .foregroundStyle(.secondary)
                } else if upcomingOccurrences.isEmpty {
                    Text("Nothing else expected this month.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            if recurringTransactionsCount > 0 {
                NavigationLink(destination: allOccurrences) {
                    Text("See all expected")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .buttonStyle(TrenteSecondaryButtonStyle())
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}
