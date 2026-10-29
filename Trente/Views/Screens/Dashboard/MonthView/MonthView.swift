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
    @Query private var recurringRules: [RecurringTransactionRule]
    @Query(MonthView.anyTransactionGroupDescriptor) private var anyTransactionGroup: [TransactionGroup]

    private static var anyTransactionGroupDescriptor: FetchDescriptor<TransactionGroup> {
        var descriptor = FetchDescriptor<TransactionGroup>()
        descriptor.fetchLimit = 1
        return descriptor
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
                    Narrow(
                        month: month,
                        upcomingOccurrences: upcomingOccurrences,
                        hasTransactions: !anyTransactionGroup.isEmpty,
                        recurringTransactionsCount: recurringTransactionsCount
                    )
                } else {
                    Wide(
                        month: month,
                        upcomingOccurrences: upcomingOccurrences,
                        hasTransactions: !anyTransactionGroup.isEmpty,
                        recurringTransactionsCount: recurringTransactionsCount
                    )
                }
            }
            .navigationTitle(month.name)
            .surfacePageBackground()
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
