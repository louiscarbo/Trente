//
//  RecurrenceSchedule.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/10/2026.
//

import Foundation

struct RecurrenceSchedule {
    let frequency: RecurrenceFrequency
    let startDate: Date
    let endDate: Date?
    let earliestDate: Date

    func dates(in interval: DateInterval, calendar: Calendar = .current) -> [Date] {
        let component = frequency.calendarComponent
        let anchor = calendar.startOfDay(for: startDate)
        let lowerBound = max(
            anchor,
            calendar.startOfDay(for: earliestDate),
            calendar.startOfDay(for: interval.start)
        )
        let upperBound = exclusiveUpperBound(of: interval, calendar: calendar)
        guard lowerBound < upperBound else { return [] }

        let elapsedPeriods = calendar.dateComponents([component], from: anchor, to: lowerBound).value(for: component) ?? 0
        var index = max(0, elapsedPeriods - 1)
        var dates: [Date] = []
        while let date = calendar.date(byAdding: component, value: index, to: anchor), date < upperBound {
            if date >= lowerBound {
                dates.append(date)
            }
            index += 1
        }
        return dates
    }

    func firstDate(onOrAfter date: Date, calendar: Calendar = .current) -> Date? {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: frequency.calendarComponent, value: 1, to: start) else { return nil }
        return dates(in: DateInterval(start: start, end: end), calendar: calendar).first
    }

    private func exclusiveUpperBound(of interval: DateInterval, calendar: Calendar) -> Date {
        guard let endDate else { return interval.end }
        let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        return min(interval.end, dayAfterEnd)
    }
}

extension RecurrenceFrequency {
    var calendarComponent: Calendar.Component {
        switch self {
        case .weekly: .weekOfYear
        case .monthly: .month
        case .yearly: .year
        }
    }
}
