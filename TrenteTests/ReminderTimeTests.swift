//
//  ReminderTimeTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct ReminderTimeTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReminderTimeTests.\(UUID().uuidString)")!
    }

    @Test("Without a stored time, reminders go out at nine")
    func defaultsToNine() {
        #expect(ReminderTime.stored(in: makeDefaults()) == ReminderTime(hour: 9, minute: 0))
    }

    @Test("A stored time is read back")
    func roundTrip() {
        let defaults = makeDefaults()
        ReminderTime(hour: 7, minute: 30).store(in: defaults)

        #expect(ReminderTime.stored(in: defaults) == ReminderTime(hour: 7, minute: 30))
    }

    @Test("An invalid stored time falls back to nine", arguments: [(24, 0), (-1, 0), (9, 60)])
    func invalidFallsBack(hour: Int, minute: Int) {
        let defaults = makeDefaults()
        defaults.set(hour, forKey: ReminderTime.hourKey)
        defaults.set(minute, forKey: ReminderTime.minuteKey)

        #expect(ReminderTime.stored(in: defaults) == .standard)
    }

    @Test("The reminder lands at its time on the given day")
    func dateOnDay() throws {
        let day = try #require(calendar.date(from: DateComponents(year: 2025, month: 4, day: 15)))
        let expected = try #require(calendar.date(from: DateComponents(year: 2025, month: 4, day: 15, hour: 18, minute: 45)))

        #expect(ReminderTime(hour: 18, minute: 45).date(on: day, calendar: calendar) == expected)
    }

    @Test("A picked date keeps only its hour and minute")
    func fromDate() throws {
        let picked = try #require(calendar.date(from: DateComponents(year: 2030, month: 1, day: 2, hour: 6, minute: 5)))

        #expect(ReminderTime(date: picked, calendar: calendar) == ReminderTime(hour: 6, minute: 5))
    }
}
