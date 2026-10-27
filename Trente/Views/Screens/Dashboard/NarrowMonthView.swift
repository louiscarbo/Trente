//
//  NarrowMonthView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

struct NarrowMonthView: View {
    // Data
    let month: Month
    var upcomingOccurrences: [RecurringTransactionOccurrence]
    var transactionGroupsCount: Int
    var recurringTransactionsCount: Int
    
    // View State
    @State private var carouselPage: CarouselPage?

    private enum CarouselPage: Int, CaseIterable {
        case gauges, dailySpending
    }

    @ViewBuilder
    private func card(for page: CarouselPage) -> some View {
        switch page {
        case .gauges: SecondaryGraphCards(month: month)
        case .dailySpending: DailySpendingCard(spending: DailySpending(month: month), currencyCode: month.currency.isoCode)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                CardCarousel(selection: $carouselPage, safeAreaPadding: true) { page in
                    card(for: page)
                }

                LatestTransactionsView(
                    transactions: month.latestTransactions,
                    transactionGroupsCount: transactionGroupsCount
                ) {
                    TransactionListView(month: month, showRecurring: false)
                }
                .padding(.horizontal)

                RecurringTransactionsView(
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
