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

    let ruleID: PersistentIdentifier
    let occurrenceDate: Date
    let fireDate: Date
    let kind: Kind
    let title: String
    let body: String
}

struct RecurringNotificationPlanner {
    var horizonDays = 35
    var limit = 60
    var deliveryHour = 9
    var calendar: Calendar = .current

    func requests(
        for rules: [RecurringTransactionRule],
        currency: Currency,
        now: Date
    ) -> [RecurringNotificationRequest] {
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: horizonDays, to: start) else { return [] }
        let window = DateInterval(start: start, end: end)

        let planned = rules.flatMap { rule in
            requests(
                for: rule,
                in: window,
                currency: currency,
                now: now
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
        now: Date
    ) -> [RecurringNotificationRequest] {
        let amountCents = rule.repartition.values.reduce(0, +)
        let kind: RecurringNotificationRequest.Kind = rule.autoConfirm ? .addedAutomatically : .due
        let title = WalletNotificationService.title(
            amountCents: amountCents,
            currency: currency,
            title: rule.title
        )
        let body = Self.body(for: kind, isIncome: amountCents > 0)

        return rule.schedule.dates(in: window, calendar: calendar).compactMap { date -> RecurringNotificationRequest? in
            guard
                !rule.isSettled(on: date, calendar: calendar),
                !rule.isSkipped(on: date, calendar: calendar),
                let fireDate = calendar.date(bySettingHour: deliveryHour, minute: 0, second: 0, of: date),
                fireDate > now
            else { return nil }

            return RecurringNotificationRequest(
                ruleID: rule.persistentModelID,
                occurrenceDate: date,
                fireDate: fireDate,
                kind: kind,
                title: title,
                body: body
            )
        }
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
