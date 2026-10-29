//
//  NewMonthNotificationPlannerTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
@testable import Trente
import Foundation

struct NewMonthNotificationPlannerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()

    private var planner: NewMonthNotificationPlanner {
        NewMonthNotificationPlanner(calendar: calendar)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test("The next three months are announced at nine on their first day")
    func announcesNextThreeMonths() {
        let requests = planner.requests(afterMonthStartingOn: day(2025, 10, 1), now: day(2025, 10, 10))

        #expect(requests.map(\.startDate) == [day(2025, 11, 1), day(2025, 12, 1), day(2026, 1, 1)])
        #expect(requests.map(\.fireDate) == [day(2025, 11, 1, hour: 9), day(2025, 12, 1, hour: 9), day(2026, 1, 1, hour: 9)])
    }

    @Test("Months follow the start day of the latest month")
    func followsStartDay() {
        let requests = planner.requests(afterMonthStartingOn: day(2025, 10, 25), now: day(2025, 10, 26))

        #expect(requests.first?.startDate == day(2025, 11, 25))
    }

    @Test("The chosen reminder time replaces nine")
    func usesReminderTime() {
        let planner = NewMonthNotificationPlanner(reminderTime: ReminderTime(hour: 7, minute: 45), calendar: calendar)

        let request = planner.requests(afterMonthStartingOn: day(2025, 10, 1), now: day(2025, 10, 10)).first

        #expect(request?.fireDate == day(2025, 11, 1, hour: 7, minute: 45))
    }

    @Test("A month whose reminder has already passed is skipped")
    func skipsPassedReminder() {
        let requests = planner.requests(afterMonthStartingOn: day(2025, 10, 1), now: day(2025, 11, 1, hour: 10))

        #expect(requests.first?.startDate == day(2025, 12, 1))
        #expect(requests.count == 3)
    }

    @Test("The title names the new month like the month list does")
    func titleNamesMonth() {
        let request = planner.requests(afterMonthStartingOn: day(2025, 10, 1), now: day(2025, 10, 10)).first

        #expect(request?.title == NewMonthNotificationPlanner.title(forMonthStartingOn: day(2025, 11, 1)))
        #expect(request?.title.contains(Month.name(startingOn: day(2025, 11, 1))) == true)
        #expect(request?.body == NewMonthNotificationPlanner.body)
    }

    @Test("The identifier is made of the month's first day")
    func identifierUsesStartDay() throws {
        let request = try #require(planner.requests(afterMonthStartingOn: day(2025, 10, 1), now: day(2025, 10, 10)).first)

        #expect(request.identifier == "newMonth.2025-11-01")
    }

    @Test("Turned off, no new month is announced")
    func disabledAnnouncesNothing() {
        let planner = NewMonthNotificationPlanner(isEnabled: false, calendar: calendar)

        #expect(planner.requests(afterMonthStartingOn: day(2025, 10, 1), now: day(2025, 10, 10)).isEmpty)
    }
}
