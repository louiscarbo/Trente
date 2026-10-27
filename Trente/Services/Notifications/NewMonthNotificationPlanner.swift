//
//  NewMonthNotificationPlanner.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

struct NewMonthNotificationRequest: Equatable {
    let identifier: String
    let startDate: Date
    let fireDate: Date
    let title: String
    let body: String
}

struct NewMonthNotificationPlanner {
    static let identifierPrefix = "newMonth."
    static let threadIdentifier = "newMonth"

    var isEnabled = true
    var count = 3
    var reminderTime = ReminderTime.standard
    var calendar: Calendar = .current

    private let maximumMonthsAhead = 1200

    func requests(afterMonthStartingOn latestStartDate: Date, now: Date) -> [NewMonthNotificationRequest] {
        guard isEnabled else { return [] }
        var requests: [NewMonthNotificationRequest] = []
        var startDate = calendar.startOfDay(for: latestStartDate)
        var monthsAhead = 0
        while requests.count < count, monthsAhead < maximumMonthsAhead {
            guard let nextStartDate = calendar.date(byAdding: .month, value: 1, to: startDate) else { break }
            startDate = nextStartDate
            monthsAhead += 1
            guard let fireDate = reminderTime.date(on: startDate, calendar: calendar), fireDate > now else { continue }
            requests.append(
                NewMonthNotificationRequest(
                    identifier: "\(Self.identifierPrefix)\(ScheduledNotification.dayStamp(of: startDate, calendar: calendar))",
                    startDate: startDate,
                    fireDate: fireDate,
                    title: Self.title(forMonthStartingOn: startDate),
                    body: Self.body
                )
            )
        }
        return requests
    }

    static func title(forMonthStartingOn startDate: Date) -> String {
        String(localized: "\(Month.name(startingOn: startDate)) starts today")
    }

    static var body: String {
        String(localized: "Your new month is ready, with the same budget as last month. Open Trente to see it.")
    }
}

extension NewMonthNotificationRequest {
    var scheduledNotification: ScheduledNotification {
        ScheduledNotification(
            identifier: identifier,
            title: title,
            body: body,
            fireDate: fireDate,
            threadIdentifier: NewMonthNotificationPlanner.threadIdentifier
        )
    }
}
