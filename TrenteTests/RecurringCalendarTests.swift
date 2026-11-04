//
//  RecurringCalendarTests.swift
//  TrenteTests
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct RecurringCalendarTests {
    private let calendar = Calendar.current

    private func date(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
    }

    private func insertRule(
        on day: Int,
        _ repartition: [BudgetCategory: Int],
        in context: ModelContext
    ) -> RecurringTransactionRule {
        let startDate = date(11, day)
        let rule = RecurringTransactionRule(
            title: "Rule",
            frequency: .monthly,
            startDate: startDate,
            repartition: repartition,
            createdAt: startDate
        )
        context.insert(rule)
        return rule
    }

    private func days(in month: Month, rules: [RecurringTransactionRule]) -> [RecurringCalendar.Day] {
        let occurrences = RecurringTransactionService.shared.pendingOccurrences(of: rules, in: month)
        return RecurringCalendar(month: month, occurrences: occurrences).weeks.flatMap { $0 }.compactMap { $0 }
    }

    @Test("The grid follows a budget month that starts on the 25th")
    func followsBudgetMonth() throws {
        let month = insertMonth(year: 2026, month: 10, in: try makeContext())
        month.startDate = date(10, 25)
        var mondayFirst = calendar
        mondayFirst.firstWeekday = 2

        let grid = RecurringCalendar(month: month, occurrences: [], calendar: mondayFirst)
        let days = grid.weeks.flatMap { $0 }.compactMap { $0 }

        #expect(days.count == 31)
        #expect(days.first?.date == date(10, 25))
        #expect(days.last?.date == date(11, 24))
        #expect(grid.weeks.allSatisfy { $0.count == RecurringCalendar.daysPerWeek })
        #expect(grid.weeks[0].prefix(6).allSatisfy { $0 == nil })
        #expect(grid.weekdaySymbols.first == calendar.veryShortStandaloneWeekdaySymbols[1])
        #expect(days.allSatisfy { !$0.isDue })
    }

    @Test("A day shows one dot per category due, in category order")
    func oneDotPerCategory() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 11, in: context)
        let rules = [
            insertRule(on: 15, [.wants: -30_00], in: context),
            insertRule(on: 15, [.needs: -60_00], in: context),
            insertRule(on: 15, [.needs: -20_00], in: context),
            insertRule(on: 3, [.wants: -10_00], in: context)
        ]

        let days = days(in: month, rules: rules)

        #expect(days.first { $0.date == date(11, 15) }?.dueCategories == [.needs, .wants])
        #expect(days.first { $0.date == date(11, 3) }?.dueCategories == [.wants])
        #expect(days.first { $0.date == date(11, 4) }?.isDue == false)
    }

    @Test("An income split across the three categories makes three dots")
    func splitIncomeMakesThreeDots() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 11, in: context)
        let paycheck = insertRule(
            on: 1,
            [.needs: 2300_00, .wants: 1380_00, .savingsAndDebts: 920_00],
            in: context
        )
        let unsplit = insertRule(on: 2, [.needs: 0, .savingsAndDebts: 100_00], in: context)

        let days = days(in: month, rules: [paycheck, unsplit])

        #expect(days.first?.dueCategories == [.needs, .wants, .savingsAndDebts])
        #expect(days.first { $0.date == date(11, 2) }?.dueCategories == [.savingsAndDebts])
    }

    @Test("Paid and skipped occurrences leave no dot")
    func paidAndSkippedLeaveNoDot() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 11, in: context)
        let paid = insertRule(on: 5, [.needs: -60_00], in: context)
        let skipped = insertRule(on: 6, [.wants: -10_00], in: context)
        try context.save()
        let service = RecurringTransactionService.shared
        try service.confirm(try #require(paid.pendingOccurrences(in: month).first), in: context)
        try service.skip(try #require(skipped.pendingOccurrences(in: month).first), in: context)

        let days = days(in: month, rules: [paid, skipped])

        #expect(days.allSatisfy { !$0.isDue })
    }
}
