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

        private var numberStyle: AnyShapeStyle {
            if isSelected {
                return AnyShapeStyle(.background)
            }
            if !isShown || (isPast && !day.isDue) {
                return AnyShapeStyle(.tertiary)
            }
            return day.isDue ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)
        }

        var body: some View {
            Button(action: onSelect) {
                VStack(spacing: 0) {
                    Text(day.date, format: .dateTime.day())
                        .font(.subheadline.weight(day.isDue ? .semibold : .regular))
                        .monospacedDigit()
                        .lineLimit(1)
                        .foregroundStyle(numberStyle)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 29, minHeight: 22)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(.primary)
                            }
                        }
                    dots
                }
                .padding(.top, 1)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .top)
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
            .frame(height: 8)
        }
    }
}
