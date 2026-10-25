//
//  ScheduledNotification.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import Foundation
import UserNotifications

struct ScheduledNotification {
    enum Prominence {
        case alert
        case passive
    }

    let identifier: String
    let title: String
    let body: String
    let fireDate: Date
    let threadIdentifier: String
    var categoryIdentifier: String?
    var userInfo: [AnyHashable: Any] = [:]
    var prominence: Prominence = .alert
}

extension ScheduledNotification {
    var request: UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.threadIdentifier = threadIdentifier
        content.userInfo = userInfo
        if let categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        switch prominence {
        case .alert:
            content.sound = .default
        case .passive:
            content.interruptionLevel = .passive
        }

        let fireComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        )
    }
}
