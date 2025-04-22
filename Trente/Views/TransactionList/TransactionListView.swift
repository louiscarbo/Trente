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
    
    @Query(sort: \RecurringTransactionInstance.date)
    private var recurringTransactionInstances: [RecurringTransactionInstance]
    
    private var allItems: [DisplayableTransaction] {
        if showRecurring {
            return recurringTransactionInstances.map { .init(kind: .recurring($0)) }
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
    
    private var filteredAndSorted: [DisplayableTransaction] {
        allItems
            .filter { searchText.isEmpty ||
                $0.searchableString.localizedCaseInsensitiveContains(searchText)
            }
            .filter { $0.date >= dateLowerBound && $0.date <= dateUpperBound }
            .filter { tx in
                selectedCategories.isEmpty
                || tx.categories.contains(where: selectedCategories.contains)
            }
            .sorted { a, b in
                switch sortOption {
                case .dateAsc:   return a.date < b.date
                case .dateDesc:  return a.date > b.date
                case .amountAsc: return a.amountCents < b.amountCents
                case .amountDesc:return a.amountCents > b.amountCents
                case .titleAsc:  return a.title < b.title
                case .titleDesc: return a.title > b.title
                }
            }
    }
    
    private var totalDisplay: String {
        let sum = filteredAndSorted.reduce(0) { $0 + $1.amountCents }
        let code = month.currency.isoCode
        return (Double(sum)/100).formatted(.currency(code: code))
    }
    
    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(filteredAndSorted) { item in
                        item.rowView()
                    }
                }
                
                Section {
                    HStack {
                        VStack(alignment: .leading){
                            Text("Total")
                                .font(.headline)
                            Text("Sum of displayed transactions")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(totalDisplay)
                            .font(.title)
                    }
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search by title, amount, date, category…")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    SortPickerView(sortOption: $sortOption)

                    Button {
                        isShowingFilterSheet = true
                    } label: {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingFilterSheet) {
            FilterSheetView(
                dateLowerBound: $dateLowerBound,
                dateUpperBound: $dateUpperBound,
                selectedCategories: $selectedCategories,
                allItems: allItems
            )
            .presentationDetents([.medium, .large])
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
    .modelContainer(SampleDataProvider.shared.modelContainer)
}

struct FilterSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Binding var dateLowerBound: Date
    @Binding var dateUpperBound: Date
    @Binding var selectedCategories: Set<BudgetCategory>
    @State var allItems: [DisplayableTransaction]
    
    private var dateLimits: ClosedRange<Date> {
        TransactionService.shared.fetchTransactionDateBounds(from: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dates") {
                    DatePicker("From", selection: $dateLowerBound, in: dateLimits, displayedComponents: .date)
                    DatePicker("To", selection: $dateUpperBound, in: dateLimits, displayedComponents: .date)
                }
                Section("Categories") {
                    ForEach(BudgetCategory.allCases, id: \.self) { category in
                        Button {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedCategories.contains(category) ?  "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(category.color)
                                Text(category.name)
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Filter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

struct SortPickerView: View {
    @Binding var sortOption: SortOption
    
    var body: some View {
        Menu {
            Section {
                Text("Sort by")
                    .font(.headline)
            }
            // Date
            Button {
                if sortOption == .dateAsc {
                    sortOption = .dateDesc
                } else {
                    sortOption = .dateAsc
                }
            } label: {
                HStack {
                    Text("Date")
                    if sortOption == .dateAsc || sortOption == .dateDesc {
                        Image(systemName: sortOption == .dateAsc ? "chevron.up" : "chevron.down")
                    }
                }
            }
            
            // Montant
            Button {
                if sortOption == .amountAsc {
                    sortOption = .amountDesc
                } else {
                    sortOption = .amountAsc
                }
            } label: {
                HStack {
                    Text("Amount")
                    if sortOption == .amountAsc || sortOption == .amountDesc {
                        Image(systemName: sortOption == .amountAsc ? "chevron.up" : "chevron.down")
                    }
                }
            }
            
            // Titre
            Button {
                if sortOption == .titleAsc {
                    sortOption = .titleDesc
                } else {
                    sortOption = .titleAsc
                }
            } label: {
                HStack {
                    Text("Title")
                    if sortOption == .titleAsc || sortOption == .titleDesc {
                        Image(systemName: sortOption == .titleAsc ? "chevron.up" : "chevron.down")
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

enum SortOption: CaseIterable {
    case dateAsc, dateDesc
    case amountAsc, amountDesc
    case titleAsc, titleDesc

    var label: String {
        switch self {
        case .dateAsc:    return String(localized: "Date ↑")
        case .dateDesc:   return String(localized: "Date ↓")
        case .amountAsc:  return String(localized: "Montant ↑")
        case .amountDesc: return String(localized: "Montant ↓")
        case .titleAsc:   return String(localized: "Titre A→Z")
        case .titleDesc:  return String(localized: "Titre Z→A")
        }
    }
}
