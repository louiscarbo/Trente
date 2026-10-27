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

private extension Month {
    var newTransactionContext: NewTransactionContext {
        NewTransactionContext(currency: currency, monthID: persistentModelID)
    }
}

// MARK: - Shared Views
private struct LatestTransactionsView<AllTransactions: View>: View {
    let transactions: [TransactionGroup]
    let transactionGroupsCount: Int
    var transactionCount: Int = 3
    @ViewBuilder let allTransactions: () -> AllTransactions

    var body: some View {
        let latestTransactions = Array(transactions.prefix(transactionCount))

        GroupBox(label: Label("Latest Transactions", systemImage: "clock.arrow.circlepath")) {
            ForEach(latestTransactions) { transaction in
                TransactionGroupRowView(transactionGroup: transaction)
                
                if transaction != latestTransactions.last {
                    Divider()
                }
            }
            
            HStack {
                if transactionGroupsCount == 0 {
                    Text("Add your first transaction by tapping 'Add Transaction'.")
                        .foregroundStyle(.secondary)
                } else if latestTransactions.isEmpty {
                    Text("Add your first transaction for this month by tapping 'Add Transaction'.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            if transactionGroupsCount > 0 {
                NavigationLink(destination: allTransactions) {
                    Text("See all transactions")
                }
                .buttonStyle(TrenteSecondaryButtonStyle())
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

private struct RecurringTransactionsView<AllOccurrences: View>: View {
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

private struct SecondaryGraphCards: View {
    var month: Month
    var size: CGFloat = 80
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                card(for: .all)
                card(for: .category(.needs))
            }
            HStack(spacing: 20) {
                card(for: .category(.wants))
                card(for: .category(.savingsAndDebts))
            }
        }
    }

    private func card(for scope: BudgetScope) -> some View {
        GraphCardView(
            figures: month.figures(in: scope),
            scope: scope,
            currency: month.currency,
            size: size
        )
    }
}

private struct AddTransactionButton: View {
    let context: NewTransactionContext
    var wide: Bool = false
    
    @State private var isShowingNewTransactionSheet: Bool = false
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button {
            #if os(iOS)
            isShowingNewTransactionSheet = true
            #else
            openWindow(id: WindowIdentifiers.newTransaction, value: context)
            #endif
        } label: {
            Label("Add Transaction", systemImage: "plus")
                .font(.title)
        }
        .buttonStyle(TrentePrimaryButtonStyle())
        .padding(.horizontal)
        .padding(.top)
        .frame(width: wide ? 400 : nil)
        #if os(macOS)
        .padding(.bottom)
        #else
        .sheet(isPresented: $isShowingNewTransactionSheet) {
            NewTransactionView(context: context)
        }
        #endif
    }
}

// MARK: Narrow view
private struct NarrowMonthView: View {
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

// MARK: Wide view
private struct WideMonthView: View {
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
