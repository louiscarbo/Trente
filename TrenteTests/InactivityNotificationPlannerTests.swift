//
//  InactivityNotificationPlannerTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct InactivityNotificationPlannerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()

    private var planner: InactivityNotificationPlanner {
        InactivityNotificationPlanner(calendar: calendar)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func reminder(_ identifier: String, firingAt fireDate: Date) -> ScheduledNotification {
        ScheduledNotification(
            identifier: identifier,
            title: identifier,
            body: "",
            fireDate: fireDate,
            threadIdentifier: "test"
        )
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "InactivityNotificationPlannerTests.\(UUID().uuidString)")!
    }

    @Test("The goodbye goes out at the reminder time a week after the last open")
    func goodbyeAWeekLater() {
        #expect(planner.goodbyeDate(lastAppOpen: day(2026, 10, 27, hour: 20)) == day(2026, 11, 3, hour: 9))
    }

    @Test("The goodbye uses the chosen reminder time")
    func goodbyeUsesReminderTime() {
        let planner = InactivityNotificationPlanner(reminderTime: ReminderTime(hour: 18, minute: 30), calendar: calendar)

        #expect(planner.goodbyeDate(lastAppOpen: day(2026, 10, 27, hour: 8)) == day(2026, 11, 3, hour: 18, minute: 30))
    }

    @Test("Reminders after the goodbye are dropped and the goodbye comes last")
    func dropsRemindersAfterGoodbye() {
        let reminders = [
            reminder("tomorrow", firingAt: day(2026, 10, 28, hour: 9)),
            reminder("sixDays", firingAt: day(2026, 11, 2, hour: 9)),
            reminder("sameTimeAsGoodbye", firingAt: day(2026, 11, 3, hour: 9)),
            reminder("nextMonth", firingAt: day(2026, 11, 25, hour: 9))
        ]

        let notifications = planner.notifications(keeping: reminders, lastAppOpen: day(2026, 10, 27, hour: 12))

        #expect(notifications.map(\.identifier) == ["tomorrow", "sixDays", InactivityNotificationPlanner.goodbyeIdentifier])
        #expect(notifications.last?.fireDate == day(2026, 11, 3, hour: 9))
    }

    @Test("The goodbye is scheduled even without reminders in the week")
    func goodbyeWithoutReminders() {
        let reminders = [reminder("nextMonth", firingAt: day(2026, 11, 25, hour: 9))]

        let withoutReminders = planner.notifications(keeping: [], lastAppOpen: day(2026, 10, 27))
        let withLaterReminder = planner.notifications(keeping: reminders, lastAppOpen: day(2026, 10, 27))

        #expect(withoutReminders.map(\.identifier) == [InactivityNotificationPlanner.goodbyeIdentifier])
        #expect(withLaterReminder.map(\.identifier) == [InactivityNotificationPlanner.goodbyeIdentifier])
    }

    @Test("Opening the app again moves the goodbye and keeps later reminders")
    func reopeningMovesCutoff() {
        let reminders = [
            reminder("tomorrow", firingAt: day(2026, 10, 28, hour: 9)),
            reminder("inTenDays", firingAt: day(2026, 11, 6, hour: 9))
        ]

        let beforeReopening = planner.notifications(keeping: reminders, lastAppOpen: day(2026, 10, 27, hour: 12))
        let afterReopening = planner.notifications(keeping: reminders, lastAppOpen: day(2026, 10, 31, hour: 12))

        #expect(beforeReopening.map(\.identifier) == ["tomorrow", InactivityNotificationPlanner.goodbyeIdentifier])
        #expect(afterReopening.map(\.identifier) == ["tomorrow", "inTenDays", InactivityNotificationPlanner.goodbyeIdentifier])
        #expect(afterReopening.last?.fireDate == day(2026, 11, 7, hour: 9))
    }

    @Test("The goodbye mentions the last time the app was opened")
    func goodbyeContent() {
        let lastAppOpen = day(2026, 10, 27, hour: 12)
        let goodbye = InactivityNotificationPlanner.goodbye(on: day(2026, 11, 3, hour: 9), lastAppOpen: lastAppOpen)

        #expect(goodbye.title == NotificationText.goodbyeTitle)
        #expect(goodbye.body == NotificationText.goodbyeBody(lastAppOpen: lastAppOpen))
        #expect(goodbye.body.contains(lastAppOpen.formatted(.dateTime.day().month(.wide))))
        #expect(goodbye.categoryIdentifier == nil)
        #expect(!goodbye.identifier.hasPrefix(RecurringNotificationPlanner.identifierPrefix))
    }

    @Test("The last app open is stored and read back")
    func lastAppOpenRoundTrip() {
        let defaults = makeDefaults()
        let openedAt = day(2026, 10, 27, hour: 8)

        #expect(InactivityNotificationPlanner.storedLastAppOpen(in: defaults) == nil)
        InactivityNotificationPlanner.recordAppOpen(at: openedAt, in: defaults)
        #expect(InactivityNotificationPlanner.storedLastAppOpen(in: defaults) == openedAt)
    }
}
