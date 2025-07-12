//
//  MonthView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI

struct MonthView: View {
    @State var month: Month
    
    var latestTransactions: [TransactionGroup] { month.latestTransactions }
    
    var nextRecurringTransactionsInstances: [RecurringTransactionInstance] {
        let now = Date()
        return month.recurringTransactionInstances
            .sorted { a, b in
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
    
    var body: some View {
        WidthThresholdReader(widthThreshold: 730) { proxy in
            Group {
                if proxy.isCompact {
                    NarrowMonthView(
                        month: month,
                        latestTransactions: latestTransactions,
                        nextRecurringTransactionsInstances: nextRecurringTransactionsInstances
                    )
                } else {
                    WideMonthView(
                        month: month,
                        latestTransactions: latestTransactions,
                        nextRecurringTransactionsInstances: nextRecurringTransactionsInstances
                    )
                }
            }
            .navigationTitle(month.name)
        }
    }
}

#Preview {
    ContentView()
}

// MARK: Narrow view
private struct NarrowMonthView: View {
    @State var month: Month
    
    @State var latestTransactions: [TransactionGroup]
    @State var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    
    // View Specific Variables
    @Environment(\.modelContext) var modelContext
    @State private var isShowingTransactionList = false
    @State private var isShowingNewTransactionSheet = false
    @Environment(\.colorScheme) private var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    private var transactionGroupsCount: Int {
        TransactionService.shared.fetchTransactionsCount(from: modelContext)
    }
    private var recurringTransactionsCount: Int { fetchRecurringTransactionsCount() }
    
    @State private var error: Error?
    @State private var errorIsPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Graphs ScrollView
                        ScrollView(.horizontal) {
                            HStack(spacing: 20) {
                                GroupBox(label: Label("Monthly Overview", systemImage: "chart.pie.fill")) {
                                    Text("Graph Card")
                                        .font(.title)
                                        .frame(width: 300, height: 280)
                                }
                                .groupBoxStyle(TrenteGroupBoxStyle())
                                
                                VStack(spacing: 20) {
                                    HStack(spacing: 20) {
                                        GraphCardView(
                                            month: month,
                                            category: BudgetCategory.needs,
                                            size: 80,
                                            scaleHorizontally: false
                                        )
                                        GraphCardView(
                                            month: month,
                                            category: BudgetCategory.wants,
                                            size: 80,
                                            scaleHorizontally: false
                                        )
                                    }
                                    GraphCardView(month: month, category: BudgetCategory.savingsAndDebts, size: 80)
                                }
                            }
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollIndicators(.hidden)
                        .safeAreaPadding(.horizontal)
                        .safeAreaPadding(.vertical, 3)
                        
                        // Transactions
                        GroupBox(label: Label("Latest Transactions", systemImage: "clock.arrow.circlepath")) {
                            ForEach(latestTransactions.prefix(3)) { transaction in
                                TransactionGroupRowView(transactionGroup: transaction)
                                
                                if transaction != latestTransactions.prefix(3).last {
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
                        .padding(.horizontal)
                        .groupBoxStyle(TrenteGroupBoxStyle())
                        
                        // Recurring Transactions
                        GroupBox(label: Label("Recurring Transactions", systemImage: "clock.arrow.circlepath")) {
                            ForEach(nextRecurringTransactionsInstances.prefix(3)) { recurringTransactionInstance in
                                RecurringTransactionRowView(instance: recurringTransactionInstance)
                                
                                if recurringTransactionInstance != nextRecurringTransactionsInstances.prefix(3).last {
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
                        .padding(.horizontal)
                        .groupBoxStyle(TrenteGroupBoxStyle())
                        
                        Spacer()
                            .frame(height: 100)
                    }
                }
                
                Rectangle()
                    .ignoresSafeArea()
                    .frame(height: 150)
                    .foregroundStyle(
                        lightMode ?
                        LinearGradient(
                            colors: [.clear, .white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
                
                Button {
                    isShowingNewTransactionSheet = true
                } label: {
                    Label("Add Transaction", systemImage: "plus")
                        .font(.title)
                }
                .buttonStyle(TrentePrimaryButtonStyle())
                .padding()
                .padding(.horizontal)
                .sheet(isPresented: $isShowingNewTransactionSheet) {
                    NewTransactionView(currency: month.currency)
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
    @State var month: Month
    @State var latestTransactions: [TransactionGroup]
    @State var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    @State var isShowingNewTransactionSheet: Bool = false
    
    // View properties
    @Environment(\.colorScheme) private var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        // Graph Card
                        GridRow {
                            GroupBox(label:
                                        Label("Monthly Overview", systemImage: "chart.pie.fill")
                            ) {
                                Text("Graph Card")
                                    .font(.title)
                                    .frame(height: 350)
                            }
                            .groupBoxStyle(TrenteGroupBoxStyle())
                            GroupBox(label:
                                        Label("Latest Transactions", systemImage: "clock.arrow.circlepath")
                            ) {
                                List {
                                    ForEach(latestTransactions.prefix(5)) { transaction in
                                        TransactionGroupRowView(transactionGroup: transaction)
                                    }
                                    
                                    NavigationLink {
                                        TransactionListView(month: month, showRecurring: false)
                                    } label: {
                                        Text("See all transactions")
                                    }
                                }
                                .listStyle(.inset)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.secondary.opacity(0.2), lineWidth: 2)
                                }
                            }
                            .groupBoxStyle(TrenteGroupBoxStyle())
                            .frame(idealWidth: 400)
                        }
                        // Other Graph Cards
                        GridRow {
                            VStack(spacing: 20) {
                                HStack(spacing: 20) {
                                    GraphCardView(month: month, category: BudgetCategory.needs)
                                    GraphCardView(month: month, category: BudgetCategory.wants)
                                }
                                GraphCardView(month: month, category: BudgetCategory.savingsAndDebts)
                            }
                            GroupBox(label:
                                        Label("Next Recurring Transactions", systemImage: "clock.arrow.circlepath")
                            ) {
                                List {
                                    ForEach(nextRecurringTransactionsInstances.prefix(5)) { transaction in
                                        RecurringTransactionRowView(instance: transaction)
                                    }
                                    
                                    NavigationLink {
                                        TransactionListView(month: month, showRecurring: true)
                                    } label: {
                                        Text("See all recurring transactions")
                                    }
                                }
                                .listStyle(.inset)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.secondary.opacity(0.2), lineWidth: 2)
                                }
                            }
                            .groupBoxStyle(TrenteGroupBoxStyle())
                        }
                        GridRow {
                            Spacer()
                                .frame(height: 150)
                        }
                    }
                    .padding(35)
                }
                
                Capsule()
                    .fill(
                        lightMode ? Color.white :
                        Color.black.opacity(0.8)
                    )
                    .stroke(
                        lightMode ? Color.white :
                            Color.black.opacity(0.8),
                        lineWidth: 40
                    )
                    .frame(width: 300, height: 70)
                    .padding()
                    .padding(.horizontal)
                    .blur(radius: 30)
                
                Button {
                    isShowingNewTransactionSheet = true
                } label: {
                    Label("Add Transaction", systemImage: "plus")
                        .font(.title2)
                }
                .buttonStyle(TrentePrimaryButtonStyle())
                .frame(width: 300, height: 70)
                .padding()
                .padding(.horizontal)
                .sheet(isPresented: $isShowingNewTransactionSheet) {
                    NewTransactionView(currency: month.currency)
                }
            }
        }
    }
}
