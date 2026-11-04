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
    let onLeave: () -> Void
    @Query private var recurringRules: [RecurringTransactionRule]
    @Query(MonthView.anyTransactionGroupDescriptor) private var anyTransactionGroup: [TransactionGroup]
    @Query(sort: \PendingTransaction.date, order: .reverse, animation: .default) private var pendingTransactions: [PendingTransaction]
    @Query(MonthView.latestMonthDescriptor) private var latestMonths: [Month]

    @State private var pendingReview: PendingReview?
    @State private var pendingTransactionRouter = PendingTransactionRouter.shared

    private static var anyTransactionGroupDescriptor: FetchDescriptor<TransactionGroup> {
        var descriptor = FetchDescriptor<TransactionGroup>()
        descriptor.fetchLimit = 1
        return descriptor
    }

    private static var latestMonthDescriptor: FetchDescriptor<Month> {
        var descriptor = FetchDescriptor<Month>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        descriptor.fetchLimit = 1
        return descriptor
    }

    private var pendingCurrencyCode: String {
        (latestMonths.first ?? month).currency.isoCode
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
                        pendingTransactions: pendingTransactions,
                        pendingCurrencyCode: pendingCurrencyCode,
                        hasTransactions: !anyTransactionGroup.isEmpty,
                        recurringTransactionsCount: recurringTransactionsCount,
                        onReviewPending: { pendingReview = $0 }
                    )
                } else {
                    Wide(
                        month: month,
                        upcomingOccurrences: upcomingOccurrences,
                        pendingTransactions: pendingTransactions,
                        pendingCurrencyCode: pendingCurrencyCode,
                        hasTransactions: !anyTransactionGroup.isEmpty,
                        recurringTransactionsCount: recurringTransactionsCount,
                        onReviewPending: { pendingReview = $0 }
                    )
                }
            }
            .sheet(item: $pendingReview) { review in
                switch review {
                case .all:
                    PendingTransactionsListView(currencyCode: pendingCurrencyCode)
                case .purchase(let id):
                    PendingTransactionReviewLoader(id: id)
                }
            }
            .onChange(of: pendingTransactionRouter.presentedPendingTransactionID) { _, id in
                if id != nil { pendingReview = nil }
            }
            .navigationTitle(month.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        MonthDetailsView(month: month, onLeave: onLeave)
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
