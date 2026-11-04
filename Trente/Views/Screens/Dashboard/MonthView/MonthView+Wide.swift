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
        @State private var foldColumns: FoldColumns?

        private enum CarouselPage: Int, CaseIterable {
            case gauges, dailySpending
        }

        private var gridInsets: EdgeInsets {
            EdgeInsets(
                top: 26,
                leading: foldColumns == nil ? 26 : FoldColumns.leadingMargin,
                bottom: 26,
                trailing: foldColumns == nil ? 26 : FoldColumns.trailingMargin
            )
        }

        @ViewBuilder
        private func card(for page: CarouselPage) -> some View {
            switch page {
            case .gauges: BudgetGauges(month: month)
            case .dailySpending:
                DailySpendingCard(
                    spending: DailySpending(month: month),
                    currencyCode: month.currency.isoCode,
                    stretchesChart: true
                )
            }
        }

        var body: some View {
            ScrollView {
                Grid(
                    horizontalSpacing: foldColumns?.spacing ?? DesignSystem.Spacing.grid.rawValue,
                    verticalSpacing: DesignSystem.Spacing.grid.rawValue
                ) {
                    GridRow {
                        BudgetRingsCard(rings: BudgetRings(month: month))
                            .frame(width: foldColumns?.leadingWidth)
                        LatestTransactions(
                            transactions: month.latestTransactions,
                            hasTransactions: hasTransactions,
                            transactionCount: 5
                        ) {
                            TransactionListView(month: month, showRecurring: false)
                        }
                        .frame(idealWidth: 400)
                        .frame(width: foldColumns?.trailingWidth)
                    }
                    GridRow {
                        CardCarousel(selection: $carouselPage) { page in
                            card(for: page)
                        }
                        .frame(width: foldColumns?.leadingWidth)
                        UpcomingRecurring(
                            month: month,
                            upcomingOccurrences: upcomingOccurrences,
                            recurringTransactionsCount: recurringTransactionsCount,
                            transactionCount: 5
                        ) {
                            TransactionListView(month: month, showRecurring: true)
                        }
                        .frame(width: foldColumns?.trailingWidth)
                    }
                }
                .padding(gridInsets)
            }
            .safeAreaInset(edge: .bottom, alignment: foldColumns == nil ? .center : .trailing) {
                AddTransactionButton(context: month.newTransactionContext, slotWidth: foldColumns?.addButtonSlotWidth ?? 400)
            }
            #if os(iOS)
            .onGeometryChange(for: FoldColumns?.self) { proxy in
                guard #available(iOS 27.1, *),
                      let fold = proxy.reservedRegions(kind: .division).first(where: \.isActive) else {
                    return nil
                }
                return FoldColumns.around(fold: fold.frame, containerWidth: proxy.size.width)
            } action: { columns in
                foldColumns = columns
            }
            #endif
        }
    }
}
