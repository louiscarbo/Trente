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
    @State var month: Month
    @Environment(\.modelContext) private var modelContext
    
    // View State
    @State private var error: Error?
    @State private var errorIsPresented: Bool = false
    
    // Computed Properties
    private var transactionGroupsCount: Int {
        fetchCount(FetchDescriptor<TransactionGroup>())
    }

    private var recurringTransactionsCount: Int {
        fetchCount(FetchDescriptor<RecurringTransactionInstance>())
    }
    
    private var nextRecurringTransactionsInstances: [RecurringTransactionInstance] {
        return month.recurringTransactionInstances
            .sorted { sortRecurringTransactions($0, $1) }
    }
    
    var body: some View {
        WidthThresholdReader(widthThreshold: 730) { proxy in
            Group {
                if proxy.isCompact {
                    NarrowMonthView(
                        month: month,
                        nextRecurringTransactionsInstances: nextRecurringTransactionsInstances,
                        transactionGroupsCount: transactionGroupsCount,
                        recurringTransactionsCount: recurringTransactionsCount
                    )
                } else {
                    WideMonthView(
                        month: month,
                        nextRecurringTransactionsInstances: nextRecurringTransactionsInstances,
                        transactionGroupsCount: transactionGroupsCount,
                        recurringTransactionsCount: recurringTransactionsCount
                    )
                }
            }
            .navigationTitle(month.name)
            .alert("An error occurred", isPresented: $errorIsPresented, presenting: error) { _ in } message: { error in
                Text("\(error.localizedDescription)")
            }
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
    
    private func sortRecurringTransactions(_ a: RecurringTransactionInstance, _ b: RecurringTransactionInstance) -> Bool {
        let now = Date()
        let aIsFuture = a.date >= now
        let bIsFuture = b.date >= now
        
        if aIsFuture == bIsFuture {
            return a.date < b.date
        }
        
        return aIsFuture
    }
    
    private func fetchCount<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> Int {
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            self.error = error
            errorIsPresented = true
            return 0
        }
    }
}

#Preview {
    MonthListView()
        .modelContainer(DataProvider.shared.modelContainer)
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
    var currency: Currency
    var month: Month
    var wide: Bool = false
    
    @State private var isShowingNewTransactionSheet: Bool = false
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    
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
    @State var month: Month
    var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    var transactionGroupsCount: Int
    var recurringTransactionsCount: Int
    
    // View State
    @State private var isShowingNewTransactionSheet = false
    @Environment(\.colorScheme) private var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 20) {
                            BudgetRingsCard(month: month)
                                .containerRelativeFrame(.horizontal)
                            PlanVsActualCard(month: month)
                                .containerRelativeFrame(.horizontal)
                            BudgetMeterCard(month: month)
                                .containerRelativeFrame(.horizontal)
                            SpendingColumnsCard(month: month)
                                .containerRelativeFrame(.horizontal)
                            DailySpendingCard(month: month)
                                .containerRelativeFrame(.horizontal)
                            SecondaryGraphCards(month: month)
                                .containerRelativeFrame(.horizontal)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
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
                ZStack(alignment: .bottom) {
                    #if os(iOS)
                    LinearGradient(
                        colors: [
                            .clear,
                            lightMode ? .white : .black
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
}

// MARK: Wide view
private struct WideMonthView: View {
    // Data
    @State var month: Month
    var nextRecurringTransactionsInstances: [RecurringTransactionInstance]
    var transactionGroupsCount: Int
    var recurringTransactionsCount: Int
    
    // View State
    @Environment(\.colorScheme) private var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow {
                        ScrollView(.horizontal) {
                            HStack(spacing: 20) {
                                BudgetRingsCard(month: month)
                                    .containerRelativeFrame(.horizontal)
                                PlanVsActualCard(month: month)
                                    .containerRelativeFrame(.horizontal)
                                BudgetMeterCard(month: month)
                                    .containerRelativeFrame(.horizontal)
                                SpendingColumnsCard(month: month)
                                    .containerRelativeFrame(.horizontal)
                                DailySpendingCard(month: month)
                                    .containerRelativeFrame(.horizontal)
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollIndicators(.hidden)
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
                .padding(26)
            }
            .safeAreaInset(edge: .bottom) {
                AddTransactionButton(currency: month.currency, month: month, wide: true)
            }
        }
    }
}
