//
//  TimelineDatesTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Testing
@testable import Trente
import Foundation

struct TimelineDatesTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func endsAtNextMidnightWithoutDueDates() {
        let now = day(2026, 3, 10, hour: 14)

        let dates = calendar.timelineDates(from: now, dueDates: [])

        #expect(dates == [now, day(2026, 3, 11)])
    }

    @Test func keepsOnlyDueDatesBeforeNextMidnight() {
        let now = day(2026, 3, 10, hour: 14)
        let laterToday = day(2026, 3, 10, hour: 18)

        let dates = calendar.timelineDates(
            from: now,
            dueDates: [day(2026, 3, 15), laterToday, day(2026, 3, 10, hour: 9)]
        )

        #expect(dates == [now, laterToday, day(2026, 3, 11)])
    }

    @Test func doesNotDuplicateDueDateAtNextMidnight() {
        let now = day(2026, 3, 10, hour: 14)

        let dates = calendar.timelineDates(from: now, dueDates: [day(2026, 3, 11)])

        #expect(dates == [now, day(2026, 3, 11)])
    }

    @Test func nextMidnightFollowsDaylightSavingChange() {
        let now = day(2026, 10, 25, hour: 1)

        let dates = calendar.timelineDates(from: now, dueDates: [])

        #expect(dates == [now, day(2026, 10, 26)])
    }
}
