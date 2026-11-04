//
//  MonthView+UpcomingRecurring.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

extension MonthView {
    struct UpcomingRecurring<AllOccurrences: View>: View {
        let month: Month
        let upcomingOccurrences: [RecurringTransactionOccurrence]
        let recurringTransactionsCount: Int
        var transactionCount: Int = 3
        @ViewBuilder let allOccurrences: () -> AllOccurrences

        @State private var selectedDay: Date?
        @State private var presentedOccurrence: RecurringTransactionOccurrence?

        private var selectedOccurrences: [RecurringTransactionOccurrence] {
            guard let selectedDay else { return [] }
            let dayOccurrences = upcomingOccurrences.filter { occurrence in
                Calendar.current.isDate(occurrence.date, inSameDayAs: selectedDay)
            }
            return Array(dayOccurrences.prefix(transactionCount))
        }

        private var dueOccurrences: [RecurringTransactionOccurrence] {
            Array(upcomingOccurrences.filter(\.isDue).prefix(transactionCount))
        }

        private var shownSelectedDay: Date? {
            selectedOccurrences.isEmpty ? nil : selectedDay
        }

        private var shownDays: Range<Date> {
            if let shownSelectedDay {
                return TransactionListFilter.days(from: shownSelectedDay, through: shownSelectedDay)
            }
            return TransactionListFilter.days(from: month.startDate, through: month.endDate())
        }

        var body: some View {
            GroupBox(label: Label("Expected This Month", systemImage: "calendar.badge.clock")) {
                if upcomingOccurrences.isEmpty {
                    HStack {
                        if recurringTransactionsCount == 0 {
                            Text("Add your first Recurring Transaction by tapping 'Add Transaction'.")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Nothing else expected this month.")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                } else {
                    RecurringCalendarGrid(
                        layout: RecurringCalendar(month: month, occurrences: upcomingOccurrences),
                        today: Calendar.current.startOfDay(for: .now),
                        shownDays: shownDays,
                        selectedDay: shownSelectedDay
                    ) { day in
                        withAnimation(.snappy) {
                            selectedDay = day == shownSelectedDay ? nil : day
                        }
                    }

                    let rows = shownSelectedDay == nil ? dueOccurrences : selectedOccurrences
                    if !rows.isEmpty {
                        Divider()
                        ForEach(rows) { occurrence in
                            RecurringTransactionRowView(occurrence: occurrence, showsDateBadge: shownSelectedDay == nil) {
                                presentedOccurrence = occurrence
                            }

                            if occurrence != rows.last {
                                Divider()
                            }
                        }
                    }
                }

                if recurringTransactionsCount > 0 {
                    NavigationLink(destination: allOccurrences) {
                        Text("See all expected")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle())
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
            .sheet(item: $presentedOccurrence) { occurrence in
                RecurringOccurrenceSheet(occurrence: occurrence)
            }
        }
    }
}
