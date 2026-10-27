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
            .formatted(.currency(code: currency.isoCode))
        return "\(amount) - \(title)"
    }

    static var goodbyeTitle: String {
        String(localized: "These reminders don't seem to help 😢")
    }

    static var goodbyeBody: String {
        String(localized: "We'll stop sending them for now. Open Trente whenever you want to pick things back up.")
    }
}
