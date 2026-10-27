//
//  TransactionListDatesTests.swift
//  TrenteTests
//

import Testing
@testable import Trente
import Foundation

struct TransactionListDatesTests {
    private let calendar = Calendar.current

    private func date(_ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func includesTheWholeLastDay() {
        let days = TransactionListView.days(from: date(10, 25), through: date(11, 24))

        #expect(days.contains(date(11, 24, hour: 23, minute: 59)))
        #expect(!days.contains(date(11, 25)))
    }

    @Test func includesTheWholeFirstDayWhenTheMonthStartedLaterThatDay() {
        let days = TransactionListView.days(from: date(10, 25, hour: 14, minute: 32), through: date(11, 24))

        #expect(days.contains(date(10, 25, hour: 9)))
        #expect(!days.contains(date(10, 24, hour: 23, minute: 59)))
    }

    @Test func monthEndDateKeepsItsLastDay() {
        let month = Month(
            startDate: date(10, 25, hour: 14),
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 0,
            idealRepartition: [:]
        )

        let days = TransactionListView.days(from: month.startDate, through: month.endDate())

        #expect(days.contains(date(11, 24, hour: 18)))
        #expect(days.lowerBound == month.dateInterval.start)
        #expect(days.upperBound == month.dateInterval.end)
    }

    @Test func emptyWhenTheRangeIsReversed() {
        let days = TransactionListView.days(from: date(11, 24), through: date(10, 25))

        #expect(days.isEmpty)
    }
}
