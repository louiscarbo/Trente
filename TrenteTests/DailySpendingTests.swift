//
//  DailySpendingTests.swift
//  TrenteTests
//

import Testing
@testable import Trente
import Foundation

struct DailySpendingTests {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func makeMonth(startingOn start: Date = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))!) -> Month {
        Month(
            startDate: start,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )
    }

    private func addExpense(
        to month: Month,
        cents: Int,
        category: BudgetCategory,
        on addedDate: Date,
        type: TransactionType = .expense
    ) {
        let group = TransactionGroup(
            title: "Test",
            type: type,
            month: month,
            note: nil,
            imageAttachmentData: nil,
            addedDate: addedDate
        )
        group.entries = [TransactionEntry(amountCents: cents, category: category, group: group)]
        month.transactionGroups.append(group)
    }

    @Test("Groups expenses by day and category")
    func groupsByDayAndCategory() {
        let month = makeMonth()
        addExpense(to: month, cents: -1000, category: .needs, on: date(2026, 3, 5, hour: 9))
        addExpense(to: month, cents: -500, category: .wants, on: date(2026, 3, 5, hour: 18))
        addExpense(to: month, cents: -250, category: .needs, on: date(2026, 3, 6))

        let spending = DailySpending(month: month, now: date(2026, 3, 10))

        #expect(spending.days.count == 2)
        #expect(spending.days[0].amounts[.needs] == 10)
        #expect(spending.days[0].amounts[.wants] == 5)
        #expect(spending.days[0].total == 15)
        #expect(spending.days[1].total == 2.5)
    }

    @Test("Ignores income")
    func ignoresIncome() {
        let month = makeMonth()
        addExpense(to: month, cents: 5000, category: .needs, on: date(2026, 3, 5), type: .income)

        let spending = DailySpending(month: month, now: date(2026, 3, 10))

        #expect(spending.days.isEmpty)
    }

    @Test("Drops groups outside the month")
    func dropsGroupsOutsideMonth() {
        let month = makeMonth()
        addExpense(to: month, cents: -1000, category: .needs, on: date(2026, 2, 28))
        addExpense(to: month, cents: -1000, category: .needs, on: date(2026, 3, 1, hour: 0))
        addExpense(to: month, cents: -1000, category: .needs, on: date(2026, 3, 31, hour: 23))
        addExpense(to: month, cents: -1000, category: .needs, on: date(2026, 4, 1))

        let spending = DailySpending(month: month, now: date(2026, 3, 10))

        #expect(spending.days.count == 2)
        #expect(spending.maxTotal(inWindowAt: nil) == 10)
    }

    @Test("Default week is the last 7 days of the current month")
    func defaultWeekStartCurrentMonth() {
        let spending = DailySpending(month: makeMonth(), now: date(2026, 3, 20))

        #expect(spending.defaultWeekStart == calendar.startOfDay(for: date(2026, 3, 14)))
        #expect(spending.today == calendar.startOfDay(for: date(2026, 3, 20)))
    }

    @Test("Default week is clamped to the month start")
    func defaultWeekStartClampedToMonthStart() {
        let spending = DailySpending(month: makeMonth(), now: date(2026, 3, 3))

        #expect(spending.defaultWeekStart == calendar.startOfDay(for: date(2026, 3, 1)))
    }

    @Test("Default week of a past month ends on its last day")
    func defaultWeekStartPastMonth() {
        let spending = DailySpending(month: makeMonth(), now: date(2026, 6, 15))

        #expect(spending.today == nil)
        #expect(spending.defaultWeekStart == calendar.startOfDay(for: date(2026, 3, 25)))
    }

    @Test("Week window covers 7 days from the start of the scrolled day")
    func weekWindow() {
        let spending = DailySpending(month: makeMonth(), now: date(2026, 3, 20))

        let window = spending.weekWindow(at: date(2026, 3, 10, hour: 15))

        #expect(window.lowerBound == calendar.startOfDay(for: date(2026, 3, 10)))
        #expect(window.upperBound == calendar.startOfDay(for: date(2026, 3, 16)))
    }

    @Test("Window max only considers days inside the window")
    func maxTotalInWindow() {
        let month = makeMonth()
        addExpense(to: month, cents: -9000, category: .needs, on: date(2026, 3, 2))
        addExpense(to: month, cents: -1000, category: .needs, on: date(2026, 3, 20))

        let spending = DailySpending(month: month, now: date(2026, 3, 25))

        #expect(spending.maxTotal(inWindowAt: date(2026, 3, 18)) == 10)
        #expect(spending.maxTotal(inWindowAt: nil) == 90)
    }

    @Test("Days in month")
    func daysInMonth() {
        #expect(DailySpending(month: makeMonth(), now: date(2026, 3, 1)).daysInMonth == 31)
        #expect(DailySpending(month: makeMonth(startingOn: date(2026, 2, 1)), now: date(2026, 3, 1)).daysInMonth == 28)
    }

    @Test("Slices carry rounded percentages and skip empty categories")
    func slices() {
        let days = [
            DailySpend(date: date(2026, 3, 1), amounts: [.needs: 2, .wants: 1])
        ]

        let slices = CategorySlice.slices(for: days)

        #expect(slices.map(\.category) == [.needs, .wants])
        #expect(slices.map(\.percent) == [67, 33])
    }

    @Test("Slices of sub-unit totals still fill the whole share")
    func slicesOfSubUnitTotal() {
        let days = [DailySpend(date: date(2026, 3, 1), amounts: [.needs: 0.5])]

        let slices = CategorySlice.slices(for: days)

        #expect(slices.count == 1)
        #expect(slices[0].share == 1)
        #expect(slices[0].percent == 100)
    }

    @Test("No slices without spending")
    func noSlices() {
        #expect(CategorySlice.slices(for: []).isEmpty)
    }
}
