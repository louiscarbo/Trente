//
//  MonthView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI

struct MonthView: View {
    @State var month: Month
        
    private var nextRecurringTransactionsInstances: [RecurringTransactionInstance] { getNextRecurringTransactionsInstance() }
    
    var body: some View {
        WidthThresholdReader(widthThreshold: 730) { proxy in
            Group {
                if proxy.isCompact {
                    NarrowMonthView(
                        month: month,
                        nextRecurringTransactionsInstances: nextRecurringTransactionsInstances
                    )
                } else {
                    WideMonthView(
                        month: month,
                        nextRecurringTransactionsInstances: nextRecurringTransactionsInstances
                    )
                }
            }
            .navigationTitle(month.name)
        }
    }
    
    private func getNextRecurringTransactionsInstance() -> [RecurringTransactionInstance] {
        return month.recurringTransactionInstances
            .sorted { a, b in
                let now = Date()
                let aIsFuture = a.date >= now
                let bIsFuture = b.date >= now
                
                switch (aIsFuture, bIsFuture) {
                    // 1) Both in the future → sort earliest first
                case (true, true):
                    return a.date < b.date
                    
                    // 2) Both in the past → sort earliest first (chronological)
                case (false, false):
                    return a.date < b.date
                    
                    // 3) One future, one past → future comes before past
                case (true, false):
                    return true
                case (false, true):
                    return false
                }
            }
    }
}

#Preview {
    ContentView()
}

// MARK: - Shared Views
private struct LatestTransactionsView: View {
    var month: Month
    var transactionGroupsCount: Int
    var transactionCount: Int = 3
    
    var body: some View {
        GroupBox(label: Label("Latest Transactions", systemImage: "clock.arrow.circlepath")) {
            ForEach(month.latestTransactions.prefix(transactionCount)) { transaction in
                TransactionGroupRowView(transactionGroup: transaction)
                
                if transaction != month.latestTransactions.prefix(transactionCount).last {
                    Divider()
                }
            }
            
            HStack {
                if transactionGroupsCount == 0 {
                    Text("Add your first transaction by tapping 'Add Transaction'.")
                        .foregroundStyle(.secondary)
                } else if month.latestTransactions.isEmpty {
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
    var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    var recurringTransactionsCount: Int
    var transactionCount: Int = 3
    
    var body: some View {
        GroupBox(label: Label("Recurring Transactions", systemImage: "clock.arrow.circlepath")) {
            ForEach(nextRecurringTransactionsInstances.prefix(transactionCount)) { recurringTransactionInstance in
                RecurringTransactionRowView(instance: recurringTransactionInstance)
                
                if recurringTransactionInstance != nextRecurringTransactionsInstances.prefix(transactionCount).last {
                    Divider()
                }
            }
            
            HStack {
                if recurringTransactionsCount == 0 {
                    Text("Add your first Recurring Transaction by tapping 'Add Transaction'.")
                        .foregroundStyle(.secondary)
                } else if nextRecurringTransactionsInstances.isEmpty {
                    Text("No upcoming recurring transactions for this month.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            if recurringTransactionsCount > 0 {
                NavigationLink {
                    TransactionListView(month: month, showRecurring: true)
                } label: {
                    Text("See all recurring transactions")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .buttonStyle(TrenteSecondaryButtonStyle())
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

private struct MainGraphCard: View {
    var body: some View {
        GroupBox(label: Label("Monthly Overview", systemImage: "chart.pie.fill")) {
            Text("Graph Card")
                .font(.title)
                .frame(width: 300, height: 280)
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
                    category: BudgetCategory.needs,
                    size: size
                )
                GraphCardView(
                    month: month,
                    category: BudgetCategory.wants,
                    size: size
                )
            }
            GraphCardView(month: month, category: BudgetCategory.savingsAndDebts, size: size)
        }
    }
}

private struct AddTransactionButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Add Transaction", systemImage: "plus")
                .font(.title)
        }
        .buttonStyle(TrentePrimaryButtonStyle())
        .padding(.horizontal)
        .padding(.top)
        #if os(macOS)
        .padding(.bottom)
        #endif
    }
}

// MARK: Narrow view
private struct NarrowMonthView: View {
    // Data
    @State var month: Month
    @State var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    @Environment(\.modelContext) private var modelContext
    
    // View State
    @State private var isShowingNewTransactionSheet = false
    @State private var error: Error?
    @State private var errorIsPresented: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    private var transactionGroupsCount: Int {
        TransactionService.shared.fetchTransactionsCount(from: modelContext)
    }
    private var recurringTransactionsCount: Int { fetchRecurringTransactionsCount() }
        
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ScrollView(.horizontal) {
                            HStack(spacing: 20) {
                                MainGraphCard()
                                SecondaryGraphCards(month: month)
                            }
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollIndicators(.hidden)
                        .safeAreaPadding(.horizontal)
                        .safeAreaPadding(.vertical, 3)
                        
                        LatestTransactionsView(
                            month: month,
                            transactionGroupsCount: transactionGroupsCount
                        )
                        .padding(.horizontal)
                        
                        RecurringTransactionsView(
                            month: month,
                            nextRecurringTransactionsInstances: nextRecurringTransactionsInstances,
                            recurringTransactionsCount: recurringTransactionsCount
                        )
                        .padding(.horizontal)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    AddTransactionButton {
                        isShowingNewTransactionSheet = true
                    }
                    .sheet(isPresented: $isShowingNewTransactionSheet) {
                        NewTransactionView(currency: month.currency)
                    }
                    .shadow(color: .white, radius: 26)
                }
            }
            .alert("An error occured", isPresented: $errorIsPresented, presenting: error) { _ in
            } message: { error in
                Text("\(error.localizedDescription)")
            }
        }
    }
    
    private func fetchRecurringTransactionsCount() -> Int {
        do {
            return try RecurringTransactionService.shared.fetchRecurringTransactionsCount(from: modelContext)
        } catch {
            self.error = error
            errorIsPresented = true
            return 0
        }
    }

}

// MARK: iPad and Mac view
private struct WideMonthView: View {
    // Data
    @State var month: Month
    @State var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    @Environment(\.modelContext) var modelContext
    
    // View State
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    private var transactionGroupsCount: Int {
        TransactionService.shared.fetchTransactionsCount(from: modelContext)
    }
    
    private var recurringTransactionsCount: Int {
        do {
            return try RecurringTransactionService.shared.fetchRecurringTransactionsCount(from: modelContext)
        } catch {
            return 0
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow {
                            MainGraphCard()
                            LatestTransactionsView(
                                month: month,
                                transactionGroupsCount: transactionGroupsCount,
                                transactionCount: 5
                            )
                            .frame(idealWidth: 400)
                        }
                        GridRow {
                            SecondaryGraphCards(month: month)
                            RecurringTransactionsView(
                                month: month,
                                nextRecurringTransactionsInstances: nextRecurringTransactionsInstances,
                                recurringTransactionsCount: recurringTransactionsCount,
                                transactionCount: 5
                            )
                        }
                    }
                    .padding(35)
                }
                .safeAreaInset(edge: .bottom) {
                    AddTransactionButton {
                        openWindow(id: "new-transaction", value: month.currency)
                    }
                    .shadow(color: .white, radius: 26)
                    .frame(width: 300)
                }
            }
        }
    }
}
