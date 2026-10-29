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

    static func goodbyeBody(lastAppOpen: Date) -> String {
        let lastOpenDay = lastAppOpen.formatted(.dateTime.day().month(.wide))
        return String(localized: "You haven't opened Trente since \(lastOpenDay), so reminders are paused. Open the app anytime to turn them back on.")
    }
}
