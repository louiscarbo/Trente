//
//  RecurringCalendarGrid+DayCell.swift
//  Trente
//

import SwiftUI

extension RecurringCalendarGrid {
    struct DayCell: View {
        let day: RecurringCalendar.Day
        let isToday: Bool
        let isPast: Bool
        let isShown: Bool
        let isSelected: Bool
        let onSelect: () -> Void

        private var numberStyle: HierarchicalShapeStyle {
            if !isShown || (isPast && !day.isDue) {
                return .tertiary
            }
            return day.isDue ? .primary : .secondary
        }

        private var monthStyle: HierarchicalShapeStyle {
            isShown && (day.isDue || !isPast) ? .secondary : .tertiary
        }

        var body: some View {
            Button(action: onSelect) {
                VStack(spacing: 0) {
                    Text(day.date, format: .dateTime.day())
                        .font(.title3.weight(day.isDue ? .semibold : .regular))
                        .foregroundStyle(numberStyle)
                    Text(day.date, format: .dateTime.month(.abbreviated))
                        .font(.footnote)
                        .textCase(.uppercase)
                        .foregroundStyle(monthStyle)
                    dots
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 5)
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .top)
                .background {
                    if isToday {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.fill.tertiary)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(day.isDue)
            .accessibilityRemoveTraits(day.isDue ? [] : .isButton)
            .accessibilityLabel(Text(day.date, format: .dateTime.day().month(.wide)))
            .accessibilityValue(Text(day.dueCategories.map(\.name).formatted(.list(type: .and))))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

        private var dots: some View {
            HStack(spacing: 3) {
                ForEach(day.dueCategories) { category in
                    Circle()
                        .fill(category.color)
                        .frame(width: 6, height: 6)
                }
            }
            .opacity(isShown ? 1 : 0.35)
            .frame(height: 10)
        }
    }
}
