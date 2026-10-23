//
//  MonthServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@Suite(.serialized)
struct MonthServiceTests {

    @Test("The latest month by start date is the current one")
    func latestMonth() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 8, in: context)
        let latest = insertMonth(year: 2026, month: 10, in: context)
        insertMonth(year: 2026, month: 9, in: context)

        let found = try MonthService.shared.latestMonth(in: context)

        #expect(found?.id == latest.id)
    }

    @Test("There is no latest month when none exist")
    func latestMonthWithoutMonths() throws {
        let context = try makeContext()

        #expect(try MonthService.shared.latestMonth(in: context) == nil)
    }

    @Test("Missing months chain from the latest one up to today", arguments: MissingMonthsCase.all)
    func startDatesOfMissingMonths(missingMonthsCase: MissingMonthsCase) {
        let startDates = MonthService.shared.startDatesOfMissingMonths(
            after: missingMonthsCase.latestStartDate,
            today: missingMonthsCase.today,
            calendar: .paris
        )

        #expect(startDates == missingMonthsCase.expectedStartDates)
    }
}

struct MissingMonthsCase: CustomTestStringConvertible, Sendable {
    let testDescription: String
    let latestStartDate: Date?
    let today: Date
    let expectedStartDates: [Date]

    static let all: [MissingMonthsCase] = [
        MissingMonthsCase(
            testDescription: "No months",
            latestStartDate: nil,
            today: .paris(2026, 10, 23),
            expectedStartDates: []
        ),
        MissingMonthsCase(
            testDescription: "Today inside the latest month",
            latestStartDate: .paris(2026, 10, 1),
            today: .paris(2026, 10, 23, hour: 12),
            expectedStartDates: []
        ),
        MissingMonthsCase(
            testDescription: "Midnight on the boundary",
            latestStartDate: .paris(2026, 10, 1),
            today: .paris(2026, 11, 1),
            expectedStartDates: [.paris(2026, 11, 1)]
        ),
        MissingMonthsCase(
            testDescription: "Last minute of the month",
            latestStartDate: .paris(2026, 10, 1),
            today: .paris(2026, 10, 31, hour: 23, minute: 59),
            expectedStartDates: []
        ),
        MissingMonthsCase(
            testDescription: "Three months away",
            latestStartDate: .paris(2026, 7, 1),
            today: .paris(2026, 10, 23),
            expectedStartDates: [.paris(2026, 8, 1), .paris(2026, 9, 1), .paris(2026, 10, 1)]
        ),
        MissingMonthsCase(
            testDescription: "Starts on the 25th",
            latestStartDate: .paris(2026, 9, 25),
            today: .paris(2026, 11, 2),
            expectedStartDates: [.paris(2026, 10, 25)]
        ),
        MissingMonthsCase(
            testDescription: "January 31 chains to February 28 then March 28",
            latestStartDate: .paris(2026, 1, 31),
            today: .paris(2026, 3, 30),
            expectedStartDates: [.paris(2026, 2, 28), .paris(2026, 3, 28)]
        ),
        MissingMonthsCase(
            testDescription: "Time of day on the stored start is ignored",
            latestStartDate: .paris(2026, 9, 1, hour: 14, minute: 30),
            today: .paris(2026, 10, 1, hour: 8),
            expectedStartDates: [.paris(2026, 10, 1)]
        ),
        MissingMonthsCase(
            testDescription: "Daylight saving time ends during the month",
            latestStartDate: .paris(2026, 10, 1),
            today: .paris(2026, 11, 1, minute: 30),
            expectedStartDates: [.paris(2026, 11, 1)]
        ),
        MissingMonthsCase(
            testDescription: "Starts on the day daylight saving time ends",
            latestStartDate: .paris(2026, 10, 25),
            today: .paris(2026, 11, 25),
            expectedStartDates: [.paris(2026, 11, 25)]
        ),
        MissingMonthsCase(
            testDescription: "Latest month in the future",
            latestStartDate: .paris(2026, 12, 1),
            today: .paris(2026, 10, 23),
            expectedStartDates: []
        )
    ]
}

private extension Calendar {
    static var paris: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }
}

private extension Date {
    static func paris(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        Calendar.paris.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        )!
    }
}
