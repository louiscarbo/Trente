//
//  RecurringNotificationPlanner.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData

struct RecurringNotificationRequest: Equatable {
    enum Kind: Equatable {
        case due
        case addedAutomatically
    }

    let identifier: String
    let ruleID: UUID
    let occurrenceDate: Date
    let fireDate: Date
    let kind: Kind
    let isIncome: Bool
    let canBeConfirmed: Bool
    let title: String
    let body: String
}

struct RecurringNotificationPlanner {
    static let identifierPrefix = "recurring."

    var horizonDays = 35
    var limit = 60
    var reminderTime = ReminderTime.standard
    var calendar: Calendar = .current

    func requests(
        for rules: [RecurringTransactionRule],
        currency: Currency,
        now: Date,
        months: [Month] = []
    ) -> [RecurringNotificationRequest] {
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: horizonDays, to: start) else { return [] }
        let window = DateInterval(start: start, end: end)

        let planned = rules.flatMap { rule in
            requests(
                for: rule,
                in: window,
                currency: currency,
                now: now,
                months: months
            )
        }
        let sorted = planned.sorted { lhs, rhs in
            if lhs.fireDate != rhs.fireDate {
                return lhs.fireDate < rhs.fireDate
            }
            return lhs.title < rhs.title
        }
        return Array(sorted.prefix(max(0, limit)))
    }

    private func requests(
        for rule: RecurringTransactionRule,
        in window: DateInterval,
        currency: Currency,
        now: Date,
        months: [Month]
    ) -> [RecurringNotificationRequest] {
        let amountCents = rule.repartition.values.reduce(0, +)
        let kind: RecurringNotificationRequest.Kind = rule.autoConfirm ? .addedAutomatically : .due
        let title = NotificationText.amountTitle(
            amountCents: amountCents,
            currency: currency,
            title: rule.title
        )
        let isIncome = amountCents > 0
        let body = Self.body(for: kind, isIncome: isIncome)

        return rule.schedule.dates(in: window, calendar: calendar).compactMap { date -> RecurringNotificationRequest? in
            guard
                rule.isPending(on: date, calendar: calendar),
                let fireDate = reminderTime.date(on: date, calendar: calendar),
                fireDate > now
            else { return nil }

            let hasMonth = months.contains { month in month.contains(date) }
            return RecurringNotificationRequest(
                identifier: identifier(forRuleID: rule.id, on: date),
                ruleID: rule.id,
                occurrenceDate: date,
                fireDate: fireDate,
                kind: kind,
                isIncome: isIncome,
                canBeConfirmed: kind == .due && hasMonth,
                title: title,
                body: body
            )
        }
    }

    func identifiersToClear(
        delivered: [(identifier: String, payload: RecurringNotificationPayload)],
        rules: [RecurringTransactionRule]
    ) -> [String] {
        delivered.compactMap { notification in
            guard let rule = rules.first(where: { rule in rule.id == notification.payload.ruleID }) else {
                return notification.identifier
            }
            let isPending = rule.isPending(on: notification.payload.occurrenceDate, calendar: calendar)
            return isPending ? nil : notification.identifier
        }
    }

    private func identifier(forRuleID ruleID: UUID, on date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let dayString = String(
            format: "%04ld-%02ld-%02ld",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
        return "\(Self.identifierPrefix)\(ruleID.uuidString).\(dayString)"
    }

    static func body(for kind: RecurringNotificationRequest.Kind, isIncome: Bool) -> String {
        switch kind {
        case .due where isIncome:
            String(localized: "Expected today. Open Trente to mark it as received.")
        case .due:
            String(localized: "Due today. Open Trente to mark it as paid.")
        case .addedAutomatically:
            String(localized: "Added automatically.")
        }
    }
}
