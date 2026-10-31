//
//  NotificationText.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import Foundation

enum NotificationText {
    static func amountTitle(amountCents: Int, currency: Currency, title: String) -> String {
        let amount = (Double(abs(amountCents)) / 100.0)
            .formatted(.amount(currency.isoCode))
        return "\(amount) - \(title)"
    }

    static var goodbyeTitle: String {
        String(localized: "Reminders paused")
    }

    static func goodbyeBody(lastAppOpen: Date, device: ReminderDevice) -> String {
        let lastOpenDay = lastAppOpen.formatted(.dateTime.day().month(.wide))
        switch device {
        case .iPhone:
            return String(localized: """
            You haven't opened Trente on this iPhone since \(lastOpenDay), so reminders here are paused. \
            Open the app anytime to turn them back on.
            """)
        case .iPad:
            return String(localized: """
            You haven't opened Trente on this iPad since \(lastOpenDay), so reminders here are paused. \
            Open the app anytime to turn them back on.
            """)
        case .mac:
            return String(localized: """
            You haven't opened Trente on this Mac since \(lastOpenDay), so reminders here are paused. \
            Open the app anytime to turn them back on.
            """)
        }
    }
}
