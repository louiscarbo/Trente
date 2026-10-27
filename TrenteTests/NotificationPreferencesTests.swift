//
//  NotificationPreferencesTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct NotificationPreferencesTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "NotificationPreferencesTests.\(UUID().uuidString)")!
    }

    @Test("Without stored choices, every reminder is on")
    func defaultsToOn() {
        let preferences = NotificationPreferences.stored(in: makeDefaults())

        #expect(preferences == NotificationPreferences(remindsRecurringTransactions: true, announcesNewMonths: true))
    }

    @Test("Stored choices are read back")
    func readsStoredChoices() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: NotificationPreferences.recurringTransactionsKey)
        defaults.set(true, forKey: NotificationPreferences.newMonthKey)

        let preferences = NotificationPreferences.stored(in: defaults)

        #expect(preferences == NotificationPreferences(remindsRecurringTransactions: false, announcesNewMonths: true))
    }

    @Test(
        "The reminder time matters as long as one reminder is on",
        arguments: [(true, true, true), (true, false, true), (false, true, true), (false, false, false)]
    )
    func usesReminderTime(recurring: Bool, newMonth: Bool, expected: Bool) {
        let preferences = NotificationPreferences(remindsRecurringTransactions: recurring, announcesNewMonths: newMonth)

        #expect(preferences.usesReminderTime == expected)
    }
}
