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

// MARK: - Shared Views
private struct LatestTransactionsView: View {
    var month: Month
    var transactionGroupsCount: Int
    var transactionCount: Int = 3
    
    var body: some View {
        let latestTransactions = Array(month.latestTransactions.prefix(transactionCount))

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
                NavigationLink {
                    TransactionListView(month: month, showRecurring: false)
                } label: {
                    Text("See all transactions")
                }
                .buttonStyle(TrenteSecondaryButtonStyle())
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

private struct RecurringTransactionsView: View {
    var month: Month
    var upcomingOccurrences: [RecurringTransactionOccurrence]
    var recurringTransactionsCount: Int
    var transactionCount: Int = 3
    
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
                NavigationLink {
                    TransactionListView(month: month, showRecurring: true)
                } label: {
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
                GraphCardView(
                    month: month,
                    scope: .all,
                    size: size
                )
                GraphCardView(
                    month: month,
                    category: BudgetCategory.needs,
                    size: size
                )
            }
            HStack(spacing: 20) {
                GraphCardView(
                    month: month,
                    category: BudgetCategory.wants,
                    size: size
                )
                GraphCardView(
                    month: month,
                    category: BudgetCategory.savingsAndDebts,
                    size: size
                )
            }
        }
    }
}

private struct AddTransactionButton: View {
    var currency: Currency
    var month: Month
    var wide: Bool = false
    
    @State private var isShowingNewTransactionSheet: Bool = false
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button {
            #if os(iOS)
            isShowingNewTransactionSheet = true
            #else
            let context: NewTransactionContext = .init(currency: currency, monthID: month.persistentModelID)
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
            NewTransactionView(
                context: .init(currency: currency, monthID: month.persistentModelID)
            )
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
        case .dailySpending: DailySpendingCard(month: month)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                CardCarousel(selection: $carouselPage, safeAreaPadding: true) { page in
                    card(for: page)
                }

                LatestTransactionsView(
                    month: month,
                    transactionGroupsCount: transactionGroupsCount
                )
                .padding(.horizontal)
                
                RecurringTransactionsView(
                    month: month,
                    upcomingOccurrences: upcomingOccurrences,
                    recurringTransactionsCount: recurringTransactionsCount
                )
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
                AddTransactionButton(currency: month.currency, month: month)
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
        case .dailySpending: DailySpendingCard(month: month)
        }
    }

    var body: some View {
        ScrollView {
            Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                GridRow {
                    SecondaryGraphCards(month: month)
                    LatestTransactionsView(
                        month: month,
                        transactionGroupsCount: transactionGroupsCount,
                        transactionCount: 5
                    )
                    .frame(idealWidth: 400)
                }
                GridRow {
                    CardCarousel(selection: $carouselPage) { page in
                        card(for: page)
                    }
                    RecurringTransactionsView(
                        month: month,
                        upcomingOccurrences: upcomingOccurrences,
                        recurringTransactionsCount: recurringTransactionsCount,
                        transactionCount: 5
                    )
                }
            }
            .padding(26)
        }
        .safeAreaInset(edge: .bottom) {
            AddTransactionButton(currency: month.currency, month: month, wide: true)
        }
    }
}
