//
//  TransactionListView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @State var month: Month
    @State var showRecurring: Bool
    
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
    
    @State private var searchText = ""
    @State private var dateLowerBound: Date
    @State private var dateUpperBound: Date
    
    init(month: Month, showRecurring: Bool) {
        _showRecurring = State(initialValue: showRecurring)
        _month = State(initialValue: month)
        _dateLowerBound = State(
            initialValue: month.startDate
        )
        _dateUpperBound = State(
            initialValue: month.endDate()
        )
    }
    
    @State private var selectedCategories: Set<BudgetCategory> = []
    @State private var sortOption: SortOption = .dateDesc
    @State private var isShowingFilterSheet: Bool = false
    
    private var filtersAreOn: Bool {
        selectedCategories.isEmpty == false ||
        dateLowerBound != month.startDate ||
        dateUpperBound != month.endDate()
    }
    
    static func days(from firstDate: Date, through lastDate: Date, calendar: Calendar = .current) -> Range<Date> {
        let firstDay = calendar.startOfDay(for: firstDate)
        let lastDay = calendar.startOfDay(for: lastDate)
        let dayAfterLastDay = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDate
        return firstDay..<max(firstDay, dayAfterLastDay)
    }

    private var filteredAndSorted: [DisplayableTransaction] {
        let displayedDates = Self.days(from: dateLowerBound, through: dateUpperBound)
        return allItems
            .filter { searchText.isEmpty ||
                $0.searchableString.localizedStandardContains(searchText)
            }
            .filter { displayedDates.contains($0.date) }
            .filter { transaction in
                selectedCategories.isEmpty
                || transaction.categories.contains(where: selectedCategories.contains)
            }
            .sorted { a, b in
                switch sortOption {
                case .dateAsc: return a.date < b.date
                case .dateDesc: return a.date > b.date
                case .amountAsc: return a.amountCents < b.amountCents
                case .amountDesc: return a.amountCents > b.amountCents
                case .titleAsc: return a.title < b.title
                case .titleDesc: return a.title > b.title
                }
            }
    }
    
    private func totalDisplay(of items: [DisplayableTransaction]) -> String {
        let sum = items.reduce(0) { $0 + $1.amountCents }
        let code = month.currency.isoCode
        return (Double(sum)/100).formatted(.currency(code: code))
    }
    
    var body: some View {
        let items = filteredAndSorted

        VStack {
            List {
                Section {
                    ForEach(items) { item in
                        item.rowView(isInList: true)
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
                        Text(totalDisplay(of: items))
                            .font(.title)
                    }
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search by title, amount, date, category…")
            .toolbar {
                #if os(iOS)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                #endif
                ToolbarItemGroup(placement: .primaryAction) {
                    SortPickerView(sortOption: $sortOption)

                    Button {
                        isShowingFilterSheet = true
                    } label: {
                        Image(systemName: filtersAreOn ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle")
                    }
                    .sheet(isPresented: $isShowingFilterSheet) {
                        FilterSheetView(
                            dateLowerBound: $dateLowerBound,
                            dateUpperBound: $dateUpperBound,
                            selectedCategories: $selectedCategories
                        )
                        .presentationDetents([.medium, .large])
                    }
                }
            }
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
