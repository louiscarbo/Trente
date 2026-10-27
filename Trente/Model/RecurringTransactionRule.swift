//
//  RecurringTransactionRule.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    class RecurringTransactionRule {
        #Index<RecurringTransactionRule>([\.id])

        var id: UUID = UUID()
        var title: String = ""
        var frequency: RecurrenceFrequency = RecurrenceFrequency.monthly
        var startDate: Date = Date.now
        var endDate: Date?
        var autoConfirm: Bool = false
        var repartition: [BudgetCategory: Int] = [:]
        var createdAt: Date = Date.now
        var skippedOccurrenceDates: [Date] = []
        var lastAutoConfirmedDate: Date?

        @Relationship(deleteRule: .nullify, inverse: \TransactionGroup.recurringRule)
        var storedTransactions: [TransactionGroup]? = []

        init(
            title: String,
            frequency: RecurrenceFrequency,
            startDate: Date,
            endDate: Date? = nil,
            autoConfirm: Bool = false,
            repartition: [BudgetCategory: Int],
            createdAt: Date = .now
        ) {
            self.title = title
            self.frequency = frequency
            self.startDate = startDate
            self.endDate = endDate
            self.autoConfirm = autoConfirm
            self.repartition = repartition
            self.createdAt = createdAt
            self.storedTransactions = []
            Self.validateRepartitionInvariant(repartition)
        }
    }
}

extension RecurringTransactionRule {
    var amountCents: Int {
        repartition.values.reduce(0, +)
    }

    var transactions: [TransactionGroup] {
        get { storedTransactions ?? [] }
        set { storedTransactions = newValue }
    }

    func setRepartition(_ newRepartition: [BudgetCategory: Int]) {
        Self.validateRepartitionInvariant(newRepartition)
        repartition = newRepartition
    }

    fileprivate static func validateRepartitionInvariant(_ repartition: [BudgetCategory: Int]) {
        let total = repartition.values.reduce(0, +)
        if total < 0 && repartition.count > 1 {
            assertionFailure("Expense rule repartition must contain exactly one category, got \(repartition.count).")
        }
    }
}

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case weekly, monthly, yearly

    var displayName: String {
        switch self {
        case .weekly:
            String(localized: "Weekly")
        case .monthly:
            String(localized: "Monthly")
        case .yearly:
            String(localized: "Yearly")
        }
    }
}

extension RecurringTransactionRule {
    var frequencyDescription: String {
        switch frequency {
        case .weekly:
            return String(localized: "Every \(startDate.formatted(.dateTime.weekday(.wide)))")
        case .monthly:
            let day = Calendar.current.component(.day, from: startDate)
            return String(localized: "Every month on the \(day.ordinalString)")
        case .yearly:
            return String(localized: "Every \(startDate.formatted(.dateTime.month(.wide).day()))")
        }
    }
}

extension Int {
    /// “1st”, “2nd”, “3rd”, “4th”, … localized
    var ordinalString: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .ordinal
        return fmt.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension RecurringTransactionRule {
    var schedule: RecurrenceSchedule {
        RecurrenceSchedule(
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            earliestDate: createdAt
        )
    }

    func occurrences(in month: Month) -> [RecurringTransactionOccurrence] {
        schedule.dates(in: month.dateInterval).map { date in
            RecurringTransactionOccurrence(rule: self, date: date, month: month)
        }
    }

    var hasEnded: Bool {
        guard let endDate else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: endDate) <= calendar.startOfDay(for: .now)
    }

    func pendingOccurrences(in month: Month) -> [RecurringTransactionOccurrence] {
        occurrences(in: month).filter { isPending(on: $0.date) }
    }

    func isPending(on date: Date, calendar: Calendar = .current) -> Bool {
        !isSettled(on: date, calendar: calendar) && !isSkipped(on: date, calendar: calendar)
    }

    func dueAutomaticOccurrences(in month: Month, by date: Date) -> [RecurringTransactionOccurrence] {
        guard autoConfirm else { return [] }
        return pendingOccurrences(in: month).filter { occurrence in
            occurrence.date <= date && occurrence.date > (lastAutoConfirmedDate ?? .distantPast)
        }
    }

    func isSettled(on date: Date, calendar: Calendar = .current) -> Bool {
        transactions.contains { transaction in
            guard let settledDate = transaction.recurringOccurrenceDate else { return false }
            return isSamePeriod(settledDate, date, calendar: calendar)
        }
    }

    func isSkipped(on date: Date, calendar: Calendar = .current) -> Bool {
        skippedOccurrenceDates.contains { isSamePeriod($0, date, calendar: calendar) }
    }

    private func isSamePeriod(_ lhs: Date, _ rhs: Date, calendar: Calendar) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: frequency.calendarComponent)
    }
}
