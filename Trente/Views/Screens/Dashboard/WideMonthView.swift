//
//  WideMonthView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

struct WideMonthView: View {
    // Data
    let month: Month
    var upcomingOccurrences: [RecurringTransactionOccurrence]
    var transactionGroupsCount: Int
    var recurringTransactionsCount: Int
    
    // View State
    @State private var carouselPage: CarouselPage?

    private enum CarouselPage: Int, CaseIterable {
        case dailySpending
    }

    @ViewBuilder
    private func card(for page: CarouselPage) -> some View {
        switch page {
        case .dailySpending: DailySpendingCard(spending: DailySpending(month: month), currencyCode: month.currency.isoCode)
        }
    }

    var body: some View {
        ScrollView {
            Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                GridRow {
                    SecondaryGraphCards(month: month)
                    LatestTransactionsView(
                        transactions: month.latestTransactions,
                        transactionGroupsCount: transactionGroupsCount,
                        transactionCount: 5
                    ) {
                        TransactionListView(month: month, showRecurring: false)
                    }
                    .frame(idealWidth: 400)
                }
                GridRow {
                    CardCarousel(selection: $carouselPage) { page in
                        card(for: page)
                    }
                    RecurringTransactionsView(
                        upcomingOccurrences: upcomingOccurrences,
                        recurringTransactionsCount: recurringTransactionsCount,
                        transactionCount: 5
                    ) {
                        TransactionListView(month: month, showRecurring: true)
                    }
                }
            }
            .padding(26)
        }
        .safeAreaInset(edge: .bottom) {
            AddTransactionButton(context: month.newTransactionContext, wide: true)
        }
    }
}
