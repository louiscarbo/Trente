//
//  InactivityNotificationPlanner.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Foundation

struct InactivityNotificationPlanner {
    static let daysBeforeGoodbye = 7
    static let goodbyeIdentifier = "inactivity.goodbye"
    static let threadIdentifier = "inactivity"
    static let lastAppOpenKey = "notifications.lastAppOpen"

    var reminderTime = ReminderTime.standard
    var calendar: Calendar = .current

    static func storedLastAppOpen(in defaults: UserDefaults = .standard) -> Date? {
        defaults.object(forKey: lastAppOpenKey) as? Date
    }

    static func recordAppOpen(at date: Date = .now, in defaults: UserDefaults = .standard) {
        defaults.set(date, forKey: lastAppOpenKey)
    }

    func goodbyeDate(lastAppOpen: Date) -> Date? {
        let lastOpenDay = calendar.startOfDay(for: lastAppOpen)
        guard let goodbyeDay = calendar.date(byAdding: .day, value: Self.daysBeforeGoodbye, to: lastOpenDay) else {
            return nil
        }
        return reminderTime.date(on: goodbyeDay, calendar: calendar)
    }

    func notifications(keeping reminders: [ScheduledNotification], lastAppOpen: Date) -> [ScheduledNotification] {
        guard let goodbyeDate = goodbyeDate(lastAppOpen: lastAppOpen) else { return reminders }
        let keptReminders = reminders.filter { reminder in reminder.fireDate < goodbyeDate }
        return keptReminders + [Self.goodbye(on: goodbyeDate, lastAppOpen: lastAppOpen)]
    }

    static func goodbye(on fireDate: Date, lastAppOpen: Date) -> ScheduledNotification {
        ScheduledNotification(
            identifier: goodbyeIdentifier,
            title: NotificationText.goodbyeTitle,
            body: NotificationText.goodbyeBody(lastAppOpen: lastAppOpen),
            fireDate: fireDate,
            threadIdentifier: threadIdentifier
        )
    }
}
