//
//  MonthView+Narrow.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

extension MonthView {
    struct Narrow: View {
        // Data
        let month: Month
        var upcomingOccurrences: [RecurringTransactionOccurrence]
        var hasTransactions: Bool
        var recurringTransactionsCount: Int

        // View State
        @State private var carouselPage: CarouselPage?

        private enum CarouselPage: Int, CaseIterable {
            case budgetRings, gauges, dailySpending
        }

        @ViewBuilder
        private func card(for page: CarouselPage) -> some View {
            switch page {
            case .budgetRings: BudgetRingsCard(rings: BudgetRings(month: month))
            case .gauges: BudgetGauges(month: month)
            case .dailySpending: DailySpendingCard(spending: DailySpending(month: month), currencyCode: month.currency.isoCode)
            }
        }

        var body: some View {
            ScrollView {
                LazyVStack(spacing: 20) {
                    CardCarousel(selection: $carouselPage, safeAreaPadding: true) { page in
                        card(for: page)
                    }

                    LatestTransactions(
                        transactions: month.latestTransactions,
                        hasTransactions: hasTransactions
                    ) {
                        TransactionListView(month: month, showRecurring: false)
                    }
                    .padding(.horizontal)

                    UpcomingRecurring(
                        upcomingOccurrences: upcomingOccurrences,
                        recurringTransactionsCount: recurringTransactionsCount
                    ) {
                        TransactionListView(month: month, showRecurring: true)
                    }
                    .padding(.horizontal)
                }
            }
            .safeAreaInset(edge: .bottom) {
                ZStack(alignment: .bottom) {
                    #if os(iOS)
                    LinearGradient(
                        colors: [
                            .clear,
                            Color(uiColor: .systemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .frame(height: 130)
                    .offset(y: 50)
                    #endif
                    AddTransactionButton(context: month.newTransactionContext)
                }
            }
        }
    }
}
