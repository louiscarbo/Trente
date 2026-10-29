//
//  MonthView+Wide.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

extension MonthView {
    struct Wide: View {
        // Data
        let month: Month
        var upcomingOccurrences: [RecurringTransactionOccurrence]
        var hasTransactions: Bool
        var recurringTransactionsCount: Int

        // View State
        @State private var carouselPage: CarouselPage?

        private enum CarouselPage: Int, CaseIterable {
            case gauges, dailySpending
        }

        @ViewBuilder
        private func card(for page: CarouselPage) -> some View {
            switch page {
            case .gauges: BudgetGauges(month: month)
            case .dailySpending: DailySpendingCard(spending: DailySpending(month: month), currencyCode: month.currency.isoCode)
            }
        }

        var body: some View {
            ScrollView {
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow {
                        BudgetRingsCard(rings: BudgetRings(month: month))
                        LatestTransactions(
                            transactions: month.latestTransactions,
                            hasTransactions: hasTransactions,
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
                        UpcomingRecurring(
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
}
