//
//  RecurringCalendar.swift
//  Trente
//

import Foundation

struct RecurringCalendar: Equatable {
    static let daysPerWeek = 7

    struct Day: Hashable {
        let date: Date
        let dueCategories: [BudgetCategory]

        var isDue: Bool {
            !dueCategories.isEmpty
        }
    }

    let weekdaySymbols: [String]
    let weeks: [[Day?]]

    init(month: Month, occurrences: [RecurringTransactionOccurrence], calendar: Calendar = .current) {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstSymbol = calendar.firstWeekday - 1
        weekdaySymbols = Array(symbols[firstSymbol...] + symbols[..<firstSymbol])

        let firstDay = calendar.startOfDay(for: month.startDate)
        let lastDay = calendar.startOfDay(for: month.endDate())
        let categoriesByDay = Dictionary(grouping: occurrences) { occurrence in
            calendar.startOfDay(for: occurrence.date)
        }
        .mapValues(Self.dueCategories)

        let lastOffset = calendar.dateComponents([.day], from: firstDay, to: lastDay).day ?? 0
        let days: [Day?] = (0...max(0, lastOffset)).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstDay).map { date in
                Day(date: date, dueCategories: categoriesByDay[date] ?? [])
            }
        }

        let weekdayOffset = calendar.component(.weekday, from: firstDay) - calendar.firstWeekday
        let leadingBlanks = (weekdayOffset + Self.daysPerWeek) % Self.daysPerWeek
        let cells = Array(repeating: nil, count: leadingBlanks) + days
        weeks = stride(from: 0, to: cells.count, by: Self.daysPerWeek).map { start in
            let week = Array(cells[start..<min(start + Self.daysPerWeek, cells.count)])
            return week + Array(repeating: nil, count: Self.daysPerWeek - week.count)
        }
    }

    private static func dueCategories(of occurrences: [RecurringTransactionOccurrence]) -> [BudgetCategory] {
        let categories = Set(occurrences.flatMap { occurrence in
            occurrence.rule.repartition.filter { $0.value != 0 }.keys
        })
        return BudgetCategory.allCases.filter(categories.contains)
    }
}
