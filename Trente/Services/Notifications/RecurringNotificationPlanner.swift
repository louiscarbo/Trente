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
    let title: String
    let body: String
}

struct RecurringNotificationPlanner {
    static let identifierPrefix = "recurring."
    static let threadIdentifier = "recurring"

    var isEnabled = true
    var horizonDays = 35
    var reminderTime = ReminderTime.standard
    var calendar: Calendar = .current

    func requests(
        for rules: [RecurringTransactionRule],
        currency: Currency,
        now: Date
    ) -> [RecurringNotificationRequest] {
        guard isEnabled else { return [] }
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: horizonDays, to: start) else { return [] }
        let window = DateInterval(start: start, end: end)

        return rules.flatMap { rule in
            requests(
                for: rule,
                in: window,
                currency: currency,
                now: now
            )
        }
    }

    private func requests(
        for rule: RecurringTransactionRule,
        in window: DateInterval,
        currency: Currency,
        now: Date
    ) -> [RecurringNotificationRequest] {
        let amountCents = rule.amountCents
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

            return RecurringNotificationRequest(
                identifier: identifier(forRuleID: rule.id, on: date),
                ruleID: rule.id,
                occurrenceDate: date,
                fireDate: fireDate,
                kind: kind,
                isIncome: isIncome,
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
        "\(Self.identifierPrefix)\(ruleID.uuidString).\(ScheduledNotification.dayStamp(of: date, calendar: calendar))"
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

extension RecurringNotificationRequest {
    var scheduledNotification: ScheduledNotification {
        ScheduledNotification(
            identifier: identifier,
            title: title,
            body: body,
            fireDate: fireDate,
            threadIdentifier: RecurringNotificationPlanner.threadIdentifier,
            categoryIdentifier: categoryIdentifier,
            userInfo: RecurringNotificationPayload(ruleID: ruleID, occurrenceDate: occurrenceDate).userInfo,
            prominence: kind == .due ? .alert : .passive
        )
    }

    private var categoryIdentifier: String? {
        guard kind == .due else { return nil }
        return isIncome ? RecurringNotificationAction.incomeCategory : RecurringNotificationAction.expenseCategory
    }
}
