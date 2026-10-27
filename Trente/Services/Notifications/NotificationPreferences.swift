//
//  NotificationPreferences.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Foundation

struct NotificationPreferences: Equatable {
    var remindsRecurringTransactions = true
    var announcesNewMonths = true

    static let recurringTransactionsKey = "notifications.recurringTransactions"
    static let newMonthKey = "notifications.newMonth"

    static func stored(in defaults: UserDefaults = .standard) -> NotificationPreferences {
        NotificationPreferences(
            remindsRecurringTransactions: defaults.object(forKey: recurringTransactionsKey) as? Bool ?? true,
            announcesNewMonths: defaults.object(forKey: newMonthKey) as? Bool ?? true
        )
    }

    var usesReminderTime: Bool {
        remindsRecurringTransactions || announcesNewMonths
    }
}
