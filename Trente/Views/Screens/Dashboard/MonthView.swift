//
//  MonthView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI
import SwiftData

struct MonthView: View {
    // Data
    let month: Month
    @Environment(\.modelContext) private var modelContext
    @Query private var recurringRules: [RecurringTransactionRule]

    private var transactionGroupsCount: Int {
        (try? modelContext.fetchCount(FetchDescriptor<TransactionGroup>())) ?? 0
    }

    private var recurringTransactionsCount: Int {
        recurringRules.count
    }
    
    private var upcomingOccurrences: [RecurringTransactionOccurrence] {
        RecurringTransactionService.shared.pendingOccurrences(of: recurringRules, in: month)
    }
    
    var body: some View {
        WidthThresholdReader(widthThreshold: 730) { proxy in
            Group {
                if proxy.isCompact {
                    NarrowMonthView(
                        month: month,
                        upcomingOccurrences: upcomingOccurrences,
                        transactionGroupsCount: transactionGroupsCount,
                        recurringTransactionsCount: recurringTransactionsCount
                    )
                } else {
                    WideMonthView(
                        month: month,
                        upcomingOccurrences: upcomingOccurrences,
                        transactionGroupsCount: transactionGroupsCount,
                        recurringTransactionsCount: recurringTransactionsCount
                    )
                }
            }
            .navigationTitle(month.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        MonthDetailsView(month: month)
                    } label: {
                        Label("Edit Month", systemImage: "pencil")
                    }
                }
            }
        }
    }
}

#Preview {
    AppNavigationView(pendingDeepLink: .constant(nil))
        .modelContainer(DataProvider.shared.modelContainer)
}
