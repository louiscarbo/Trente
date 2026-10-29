//
//  RecurrenceScheduleTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 22/10/2026.
//

import Testing
@testable import Trente
import Foundation

struct RecurrenceScheduleTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func calendarMonth(_ year: Int, _ month: Int) -> DateInterval {
        let start = day(year, month, 1)
        return DateInterval(start: start, end: calendar.date(byAdding: .month, value: 1, to: start)!)
    }

    private func schedule(
        _ frequency: RecurrenceFrequency,
        start: Date,
        end: Date? = nil,
        earliest: Date? = nil
    ) -> RecurrenceSchedule {
        RecurrenceSchedule(
            frequency: frequency,
            startDate: start,
            endDate: end,
            earliestDate: earliest ?? start
        )
    }

    @Test("Monthly lands once on the anchor day")
    func monthlyOnAnchorDay() {
        let dates = schedule(.monthly, start: day(2025, 1, 15)).dates(in: calendarMonth(2025, 2), calendar: calendar)

        #expect(dates == [day(2025, 2, 15)])
    }

    @Test("Monthly on the 31st falls on the last day of shorter months")
    func monthlyClampsToLastDay() {
        let rule = schedule(.monthly, start: day(2025, 1, 31))

        #expect(rule.dates(in: calendarMonth(2025, 2), calendar: calendar) == [day(2025, 2, 28)])
        #expect(rule.dates(in: calendarMonth(2025, 4), calendar: calendar) == [day(2025, 4, 30)])
        #expect(rule.dates(in: calendarMonth(2025, 5), calendar: calendar) == [day(2025, 5, 31)])
        #expect(rule.dates(in: calendarMonth(2028, 2), calendar: calendar) == [day(2028, 2, 29)])
    }

    @Test("Weekly repeats on the anchor weekday")
    func weeklyOnAnchorWeekday() {
        let dates = schedule(.weekly, start: day(2025, 4, 2)).dates(in: calendarMonth(2025, 4), calendar: calendar)

        #expect(dates == [2, 9, 16, 23, 30].map { day(2025, 4, $0) })
    }

    @Test("Yearly on February 29 falls on February 28 in non-leap years")
    func yearlyLeapDay() {
        let rule = schedule(.yearly, start: day(2024, 2, 29))

        #expect(rule.dates(in: calendarMonth(2025, 2), calendar: calendar) == [day(2025, 2, 28)])
        #expect(rule.dates(in: calendarMonth(2028, 2), calendar: calendar) == [day(2028, 2, 29)])
        #expect(rule.dates(in: calendarMonth(2025, 3), calendar: calendar).isEmpty)
    }

    @Test("The time of day of the start date is ignored")
    func startTimeIsIgnored() {
        let weekly = schedule(.weekly, start: day(2025, 4, 2, hour: 14))
        let yearly = schedule(.yearly, start: day(2025, 4, 2, hour: 14))

        #expect(weekly.dates(in: calendarMonth(2025, 4), calendar: calendar).first == day(2025, 4, 2))
        #expect(yearly.dates(in: calendarMonth(2025, 4), calendar: calendar) == [day(2025, 4, 2)])
    }

    @Test("Nothing is scheduled before the start date")
    func nothingBeforeStart() {
        let dates = schedule(.monthly, start: day(2025, 6, 1)).dates(in: calendarMonth(2025, 5), calendar: calendar)

        #expect(dates.isEmpty)
    }

    @Test("Nothing is scheduled before the earliest date")
    func nothingBeforeEarliestDate() {
        let rule = schedule(.monthly, start: day(2025, 1, 15), earliest: day(2025, 3, 20, hour: 9))

        #expect(rule.dates(in: calendarMonth(2025, 2), calendar: calendar).isEmpty)
        #expect(rule.dates(in: calendarMonth(2025, 3), calendar: calendar).isEmpty)
        #expect(rule.dates(in: calendarMonth(2025, 4), calendar: calendar) == [day(2025, 4, 15)])
    }

    @Test("A payment on the earliest day itself is scheduled")
    func earliestDayIsIncluded() {
        let rule = schedule(.monthly, start: day(2025, 3, 20), earliest: day(2025, 3, 20, hour: 18))

        #expect(rule.dates(in: calendarMonth(2025, 3), calendar: calendar) == [day(2025, 3, 20)])
    }

    @Test("The end date is included and nothing comes after it")
    func endDateIsInclusive() {
        let rule = schedule(.monthly, start: day(2025, 1, 15), end: day(2025, 3, 15, hour: 8))

        #expect(rule.dates(in: calendarMonth(2025, 3), calendar: calendar) == [day(2025, 3, 15)])
        #expect(rule.dates(in: calendarMonth(2025, 4), calendar: calendar).isEmpty)
    }

    @Test("Budget months starting mid-month get the occurrences inside them")
    func budgetMonthStartingMidMonth() {
        let budgetMonth = DateInterval(start: day(2025, 1, 25), end: day(2025, 2, 25))

        #expect(schedule(.monthly, start: day(2025, 1, 10)).dates(in: budgetMonth, calendar: calendar) == [day(2025, 2, 10)])
        #expect(schedule(.monthly, start: day(2025, 1, 28)).dates(in: budgetMonth, calendar: calendar) == [day(2025, 1, 28)])
    }

    @Test("The first date on or after a day is the next one in the schedule")
    func firstDateOnOrAfter() {
        let weekly = schedule(.weekly, start: day(2025, 1, 1))
        let monthly = schedule(.monthly, start: day(2025, 1, 15))

        #expect(weekly.firstDate(onOrAfter: day(2025, 1, 10), calendar: calendar) == day(2025, 1, 15))
        #expect(monthly.firstDate(onOrAfter: day(2025, 2, 15, hour: 9), calendar: calendar) == day(2025, 2, 15))
    }

    @Test("An ended schedule has no first date after its end")
    func firstDateAfterEnd() {
        let ended = schedule(.monthly, start: day(2025, 1, 15), end: day(2025, 3, 15))

        #expect(ended.firstDate(onOrAfter: day(2025, 3, 16), calendar: calendar) == nil)
    }
}
