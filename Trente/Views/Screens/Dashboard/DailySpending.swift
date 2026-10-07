//
//  DailySpending.swift
//  Trente
//

import Foundation

struct DailySpend: Identifiable {
    let date: Date
    let amounts: [BudgetCategory: Double]
    var id: Date { date }
    var total: Double { amounts.values.reduce(0, +) }
}

struct CategorySlice {
    let category: BudgetCategory
    let amount: Double
    let share: Double

    var percent: Int { Int((share * 100).rounded()) }

    static func slices(for days: [DailySpend]) -> [CategorySlice] {
        let amounts = BudgetCategory.allCases.map { category in
            (category: category, amount: days.reduce(0) { $0 + ($1.amounts[category] ?? 0) })
        }
        let total = amounts.reduce(0) { $0 + $1.amount }
        return amounts
            .filter { $0.amount > 0 }
            .map { CategorySlice(category: $0.category, amount: $0.amount, share: $0.amount / total) }
    }
}

struct DailySpending {
    static let weekLengthInDays = 7

    let days: [DailySpend]
    let monthStartDay: Date
    let monthEndDay: Date
    let today: Date?
    private let calendar: Calendar

    init(month: Month, now: Date = .now, calendar: Calendar = .current) {
        self.calendar = calendar
        monthStartDay = calendar.startOfDay(for: month.startDate)
        monthEndDay = calendar.startOfDay(for: month.endDate())
        today = calendar.isDate(now, equalTo: month.startDate, toGranularity: .month)
            ? calendar.startOfDay(for: now)
            : nil

        var amountsByDay: [Date: [BudgetCategory: Int]] = [:]
        for group in month.transactionGroups where group.type == .expense {
            let day = calendar.startOfDay(for: group.addedDate)
            for entry in group.entries where entry.amountCents < 0 {
                amountsByDay[day, default: [:]][entry.category, default: 0] += abs(entry.amountCents)
            }
        }

        let window = monthStartDay...monthEndDay
        days = amountsByDay
            .filter { window.contains($0.key) }
            .map { DailySpend(date: $0.key, amounts: $0.value.mapValues { Double($0) / 100 }) }
            .sorted { $0.date < $1.date }
    }

    var daysInMonth: Int {
        (calendar.dateComponents([.day], from: monthStartDay, to: monthEndDay).day ?? 0) + 1
    }

    var defaultWeekStart: Date {
        let anchor = today ?? monthEndDay
        let candidate = calendar.date(byAdding: .day, value: 1 - Self.weekLengthInDays, to: anchor) ?? monthStartDay
        return max(candidate, monthStartDay)
    }

    func day(on date: Date) -> DailySpend? {
        days.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func weekWindow(at position: Date) -> ClosedRange<Date> {
        let start = calendar.startOfDay(for: position)
        let end = calendar.date(byAdding: .day, value: Self.weekLengthInDays - 1, to: start) ?? start
        return start...end
    }

    func days(inWindowAt position: Date) -> [DailySpend] {
        let window = weekWindow(at: position)
        return days.filter { window.contains($0.date) }
    }

    func maxTotal(inWindowAt position: Date?) -> Double {
        let windowDays = position.map(days(inWindowAt:)) ?? days
        return windowDays.map(\.total).max() ?? 0
    }
}
