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

    mutating func reset(for month: Month) {
        searchText = ""
        firstDay = month.startDate
        lastDay = month.endDate()
        categories = []
    }

    var shownDays: Range<Date> {
        Self.days(from: firstDay, through: lastDay)
    }

    var shownSingleDay: Date? {
        let calendar = Calendar.current
        guard calendar.isDate(firstDay, inSameDayAs: lastDay) else { return nil }
        return calendar.startOfDay(for: firstDay)
    }

    mutating func toggleDay(_ day: Date, in month: Month) {
        let tappedDay = Calendar.current.startOfDay(for: day)
        if shownSingleDay == tappedDay {
            firstDay = month.startDate
            lastDay = month.endDate()
        } else {
            firstDay = tappedDay
            lastDay = tappedDay
        }
    }

    func matchingOnAnyDay(_ items: [DisplayableTransaction]) -> [DisplayableTransaction] {
        items
            .filter { item in searchText.isEmpty || item.searchableString.localizedStandardContains(searchText) }
            .filter { item in categories.isEmpty || item.categories.contains(where: categories.contains) }
    }

    func apply(to items: [DisplayableTransaction]) -> [DisplayableTransaction] {
        let shownDays = shownDays
        return matchingOnAnyDay(items)
            .filter { item in shownDays.contains(item.date) }
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
