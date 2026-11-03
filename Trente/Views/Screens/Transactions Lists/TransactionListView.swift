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
    @Environment(\.transactionActions) private var transactionActions

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
    @State private var presentedOccurrence: RecurringTransactionOccurrence?
    @State private var rowSelection = RowSelection<DisplayableTransaction.ID>()

    init(month: Month, showRecurring: Bool) {
        self.showRecurring = showRecurring
        self.month = month
        _filter = State(initialValue: TransactionListFilter(month: month))
    }
    
    var body: some View {
        let items = filter.apply(to: allItems)
        let showsNoMatches = items.isEmpty && filter.isActive(for: month)
        let groupsToDelete = selectedGroups(in: items)

        VStack {
            List(selection: rowSelection.isActive ? $rowSelection.selectedIDs : nil) {
                if showRecurring && !showsNoMatches {
                    Section {
                        calendarGrid
                    }
                }

                Section {
                    ForEach(items) { item in
                        Row(item: item, isSelecting: rowSelection.isActive) { occurrence in
                            presentedOccurrence = occurrence
                        }
                    }
                }
                
                if !showsNoMatches && !rowSelection.isActive {
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
            }
            .overlay {
                if showsNoMatches {
                    NoMatches {
                        filter.reset(for: month)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .navigationTitle(rowSelection.isActive ? Text("\(groupsToDelete.count) Selected") : Text(showRecurring ? "Expected This Month" : "Transactions"))
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
                    .accessibilityValue(filter.isActive(for: month) ? Text("Active") : Text(verbatim: ""))
                    .sheet(isPresented: $isShowingFilterSheet) {
                        FilterSheetView(
                            dateLimits: filterDateLimits,
                            firstDay: $filter.firstDay,
                            lastDay: $filter.lastDay,
                            selectedCategories: $filter.categories,
                            canReset: filter.isActive(for: month)
                        ) {
                            filter.reset(for: month)
                        }
                        .presentationDetents([.medium, .large])
                    }
                }
            }
            .selectionMode(
                $rowSelection,
                visibleIDs: items.map(\.id),
                isAvailable: !showRecurring,
                deleteTitle: String(localized: "Delete \(groupsToDelete.count) Transactions"),
                reviewSections: { reviewSections(for: selectedGroups(in: filter.apply(to: allItems))) },
                onDelete: deleteSelectedGroups
            )
            .errorAlert(message: $errorMessage)
            .sheet(item: $presentedOccurrence) { occurrence in
                RecurringOccurrenceSheet(occurrence: occurrence)
            }
        }
    }

    private var calendarGrid: some View {
        let matchingOccurrences = filter.matchingOnAnyDay(allItems).compactMap { item in
            if case .recurring(let occurrence) = item.kind { occurrence } else { nil }
        }
        return RecurringCalendarGrid(
            layout: RecurringCalendar(month: month, occurrences: matchingOccurrences),
            today: Calendar.current.startOfDay(for: .now),
            shownDays: filter.shownDays,
            selectedDay: filter.shownSingleDay
        ) { day in
            if let day {
                filter.toggleDay(day, in: month)
            } else {
                filter.clearDay(in: month)
            }
        }
    }

    private func selectedGroups(in items: [DisplayableTransaction]) -> [TransactionGroup] {
        rowSelection.selected(in: items).compactMap { item in
            guard case .group(let group) = item.kind else { return nil }
            return group
        }
    }

    private func deleteSelectedGroups() {
        let groups = selectedGroups(in: filter.apply(to: allItems))
        transactionActions.deleteBatch {
            try BatchDeleteService.shared.delete(groups: groups, in: modelContext)
        } onSuccess: {
            rowSelection.end()
        }
    }

    private func reviewSections(for groups: [TransactionGroup]) -> [BatchDeleteReviewSheet.Section] {
        var sections: [BatchDeleteReviewSheet.Section] = [
            .willBeDeleted(
                groups.map { group in
                    .init(title: group.title, detail: group.totalAmount.formatted(.amount(group.currency.isoCode)))
                }
            )
        ]

        let budgetRows = budgetRows(for: groups)
        if !budgetRows.isEmpty {
            sections.append(
                .init(title: String(localized: "Your budget"), systemImage: "chart.pie.fill", rows: budgetRows)
            )
        }
        return sections
    }

    private func budgetRows(for groups: [TransactionGroup]) -> [BatchDeleteReviewSheet.Row] {
        let currencyCodes = Set(groups.map(\.currency.isoCode))
        guard currencyCodes.count == 1, let currencyCode = currencyCodes.first else { return [] }
        return BudgetCategory.allCases.compactMap { category in
            let totalCents = TransactionGroup.totalAmountCents(of: groups, in: category)
            guard totalCents != 0 else { return nil }
            let givenBack = (Double(-totalCents) / 100).formatted(.amount(currencyCode).sign(strategy: .always()))
            return .init(title: category.name, detail: givenBack)
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
