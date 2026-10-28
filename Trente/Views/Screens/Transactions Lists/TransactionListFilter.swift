//
//  TransactionListFilter.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Foundation

struct TransactionListFilter {
    var searchText = ""
    var firstDay: Date
    var lastDay: Date
    var categories: Set<BudgetCategory> = []
    var sort: SortOption = .dateDesc

    init(month: Month) {
        firstDay = month.startDate
        lastDay = month.endDate()
    }

    func isActive(for month: Month) -> Bool {
        !categories.isEmpty || firstDay != month.startDate || lastDay != month.endDate()
    }

    func apply(to items: [DisplayableTransaction]) -> [DisplayableTransaction] {
        let shownDays = Self.days(from: firstDay, through: lastDay)
        return items
            .filter { item in searchText.isEmpty || item.searchableString.localizedStandardContains(searchText) }
            .filter { item in shownDays.contains(item.date) }
            .filter { item in categories.isEmpty || item.categories.contains(where: categories.contains) }
            .sorted { lhs, rhs in
                switch sort {
                case .dateAsc: lhs.date < rhs.date
                case .dateDesc: lhs.date > rhs.date
                case .amountAsc: lhs.amountCents < rhs.amountCents
                case .amountDesc: lhs.amountCents > rhs.amountCents
                case .titleAsc: lhs.title < rhs.title
                case .titleDesc: lhs.title > rhs.title
                }
            }
    }

    func totalCents(of items: [DisplayableTransaction]) -> Int {
        items.reduce(0) { total, item in total + item.amountCents }
    }

    static func days(from firstDate: Date, through lastDate: Date, calendar: Calendar = .current) -> Range<Date> {
        let firstDay = calendar.startOfDay(for: firstDate)
        let lastDay = calendar.startOfDay(for: lastDate)
        let dayAfterLastDay = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDate
        return firstDay..<max(firstDay, dayAfterLastDay)
    }
}
