//
//  TransactionListView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext

    let month: Month
    let showRecurring: Bool
    
    @Query(sort: \TransactionGroup.addedDate)
    private var transactionGroups: [TransactionGroup]
    
    @Query private var recurringRules: [RecurringTransactionRule]
    
    private var allItems: [DisplayableTransaction] {
        if showRecurring {
            return RecurringTransactionService.shared.pendingOccurrences(of: recurringRules, in: month)
                .map { .init(kind: .recurring($0)) }
        } else {
            return transactionGroups.map { .init(kind: .group($0)) }
        }
    }
    
    @State private var filter: TransactionListFilter
    @State private var isShowingFilterSheet: Bool = false
    @State private var filterDateLimits = Date.distantPast...Date.distantFuture
    @State private var errorMessage: String?

    init(month: Month, showRecurring: Bool) {
        self.showRecurring = showRecurring
        self.month = month
        _filter = State(initialValue: TransactionListFilter(month: month))
    }
    
    var body: some View {
        let items = filter.apply(to: allItems)

        VStack {
            List {
                Section {
                    ForEach(items) { item in
                        Row(item: item)
                    }
                }
                
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total")
                                .font(.headline)
                            Text("Sum of displayed transactions")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Double(filter.totalCents(of: items)) / 100, format: .amount(month.currency.isoCode))
                            .font(.title)
                    }
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $filter.searchText, prompt: "Search by title, amount, date, category…")
            .toolbar {
                #if os(iOS)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                #endif
                ToolbarItemGroup(placement: .primaryAction) {
                    SortPickerView(sortOption: $filter.sort)

                    Button(
                        "Filter",
                        systemImage: filter.isActive(for: month) ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle"
                    ) {
                        showFilterSheet()
                    }
                    .sheet(isPresented: $isShowingFilterSheet) {
                        FilterSheetView(
                            dateLimits: filterDateLimits,
                            firstDay: $filter.firstDay,
                            lastDay: $filter.lastDay,
                            selectedCategories: $filter.categories
                        )
                        .presentationDetents([.medium, .large])
                    }
                }
            }
            .errorAlert(message: $errorMessage)
        }
    }

    private func showFilterSheet() {
        do {
            filterDateLimits = try TransactionService.shared.fetchTransactionDateBounds(from: modelContext)
            isShowingFilterSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    @Previewable @State var showRecurring = false
    
    let month = Month.month1
    
    VStack {
        Picker("Type", selection: $showRecurring) {
            Text("Transactions").tag(false)
            Text("Récurrentes").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        NavigationStack {
            TransactionListView(month: month, showRecurring: showRecurring)
        }
    }
}
