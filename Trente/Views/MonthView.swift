//
//  MonthView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI

struct MonthView: View {
    @State var month: Month
    
    var latestTransactions: [TransactionGroup] {
        month.transactionGroups.sorted(by: { $0.addedDate > $1.addedDate })
    }
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
        WidthThresholdReader(widthThreshold: 800) { proxy in
            
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
        .modelContainer(SampleDataProvider.shared.modelContainer)
}

struct NarrowMonthView: View {
    @State var month: Month
    
    @State var latestTransactions: [TransactionGroup]
    @State var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    
    @State private var isShowingTransactionList = false
    
    var body: some View {
        NavigationStack {
            List {
                ScrollView(.horizontal) {
                    HStack {
                        Text("Graph Card")
                            .font(.title)
                        Text("Other Graph Card")
                            .font(.subheadline)
                        Text("Other Graph Card")
                            .font(.subheadline)
                    }
                }
                
                // Transactions
                Section(header: Text("Latest transactions")) {
                    ForEach(latestTransactions.prefix(3)) { transaction in
                        TransactionGroupRowView(transactionGroup: transaction)
                    }
                    
                    if month.transactionGroups.count > 3 {
                        NavigationLink {
                            TransactionListView(month: month, showRecurring: false)
                        } label: {
                            Text("See all transactions")
                        }
                    }
                    
                    if month.transactionGroups.isEmpty {
                        Text("Add your first transaction by tapping 'Add Transaction'.")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Recurring Transactions
                Section(header: Text("Recurring Transactions")) {
                    ForEach(nextRecurringTransactionsInstances.prefix(3)) { recurringTransactionInstance in
                        RecurringTransactionRowView(recurringTransactionInstance: recurringTransactionInstance)
                    }
                    
                    if month.recurringTransactionInstances.count > 3 {
                        NavigationLink {
                            TransactionListView(month: month, showRecurring: true)
                        } label: {
                            Text("See all recurring transactions")
                        }
                    }
                }
            }
        }
    }
}

struct WideMonthView: View {
    @State var month: Month
        
    @State var latestTransactions: [TransactionGroup]
    @State var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    
    var body: some View {
        HStack {
            Grid {
                // Graph Card
                GridRow {
                    Rectangle()
                        .foregroundStyle(.red)
                        .frame(height: 400)
                    GroupBox(label:
                                Label("Latest Transactions", systemImage: "clock.arrow.circlepath")
                    ) {
                        List {
                            ForEach(latestTransactions.prefix(5)) { transaction in
                                TransactionGroupRowView(transactionGroup: transaction)
                            }
                        }
                        .listStyle(.inset)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .frame(idealWidth: 400)
                }
                // Other Graph Cards
                GridRow {
                    VStack {
                        HStack {
                            GraphCardView(month: month, category: BudgetCategory.needs)
                            GraphCardView(month: month, category: BudgetCategory.wants)
                        }
                        GraphCardView(month: month, category: BudgetCategory.savingsAndDebts)
                    }
                    GroupBox(label:
                                Label("Recurring Transactions", systemImage: "clock.arrow.circlepath")
                    ) {
                        List {
                            ForEach(nextRecurringTransactionsInstances.prefix(5)) { transaction in
                                RecurringTransactionRowView(recurringTransactionInstance: transaction)
                            }
                        }
                        .listStyle(.inset)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(35)
        }
    }
}
