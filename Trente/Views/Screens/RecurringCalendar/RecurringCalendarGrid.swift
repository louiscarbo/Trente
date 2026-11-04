//
//  RecurringCalendarGrid.swift
//  Trente
//

import SwiftUI

struct RecurringCalendarGrid: View {
    let layout: RecurringCalendar
    let today: Date
    let shownDays: Range<Date>
    let selectedDay: Date?
    let onSelectDay: (Date) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(layout.weekdaySymbols.indices, id: \.self) { index in
                    Text(layout.weekdaySymbols[index])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .top)
                }
            }
            .accessibilityHidden(true)

            ForEach(layout.weeks.indices, id: \.self) { weekIndex in
                HStack(alignment: .top, spacing: 0) {
                    ForEach(layout.weeks[weekIndex].indices, id: \.self) { dayIndex in
                        cell(for: layout.weeks[weekIndex][dayIndex])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for day: RecurringCalendar.Day?) -> some View {
        if let day {
            DayCell(
                day: day,
                isToday: day.date == today,
                isPast: day.date < today,
                isShown: shownDays.contains(day.date),
                isSelected: day.date == selectedDay
            ) {
                onSelectDay(day.date)
            }
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
        }
    }
}
