//
//  ReminderTime.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

struct ReminderTime: Equatable {
    var hour: Int
    var minute: Int

    static let standard = ReminderTime(hour: 9, minute: 0)
    static let hourKey = "recurringReminder.hour"
    static let minuteKey = "recurringReminder.minute"

    static func stored(in defaults: UserDefaults = .standard) -> ReminderTime {
        guard let hour = defaults.object(forKey: hourKey) as? Int,
              let minute = defaults.object(forKey: minuteKey) as? Int,
              (0..<24).contains(hour),
              (0..<60).contains(minute)
        else { return .standard }
        return ReminderTime(hour: hour, minute: minute)
    }

    func store(in defaults: UserDefaults = .standard) {
        defaults.set(hour, forKey: Self.hourKey)
        defaults.set(minute, forKey: Self.minuteKey)
    }

    func date(on day: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}

extension ReminderTime {
    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(
            hour: components.hour ?? ReminderTime.standard.hour,
            minute: components.minute ?? ReminderTime.standard.minute
        )
    }
}
