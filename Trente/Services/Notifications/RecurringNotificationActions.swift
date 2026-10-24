//
//  RecurringNotificationActions.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData
import UserNotifications

enum RecurringNotificationAction: String {
    case markAsPaid = "recurring.markAsPaid"
    case skip = "recurring.skip"

    static let expenseCategory = "recurring.due"
    static let incomeCategory = "recurring.due.income"

    static var categories: Set<UNNotificationCategory> {
        [
            category(identifier: expenseCategory, markTitle: String(localized: "Mark as Paid")),
            category(identifier: incomeCategory, markTitle: String(localized: "Mark as Received"))
        ]
    }

    private static func category(identifier: String, markTitle: String) -> UNNotificationCategory {
        let markAction = UNNotificationAction(
            identifier: RecurringNotificationAction.markAsPaid.rawValue,
            title: markTitle,
            options: [.authenticationRequired],
            icon: UNNotificationActionIcon(systemImageName: "checkmark.circle")
        )
        let skipAction = UNNotificationAction(
            identifier: RecurringNotificationAction.skip.rawValue,
            title: String(localized: "Skip"),
            options: [.authenticationRequired],
            icon: UNNotificationActionIcon(systemImageName: "forward.end")
        )
        return UNNotificationCategory(
            identifier: identifier,
            actions: [markAction, skipAction],
            intentIdentifiers: [],
            options: []
        )
    }
}

struct RecurringNotificationPayload: Equatable {
    static let ruleIDKey = "recurringRuleID"
    static let occurrenceDateKey = "occurrenceDate"

    let ruleID: UUID
    let occurrenceDate: Date

    var userInfo: [AnyHashable: Any] {
        [
            Self.ruleIDKey: ruleID.uuidString,
            Self.occurrenceDateKey: occurrenceDate.timeIntervalSinceReferenceDate
        ]
    }
}

extension RecurringNotificationPayload {
    init?(userInfo: [AnyHashable: Any]) {
        guard let ruleIDString = userInfo[Self.ruleIDKey] as? String,
              let ruleID = UUID(uuidString: ruleIDString),
              let timestamp = userInfo[Self.occurrenceDateKey] as? Double
        else { return nil }
        self.init(ruleID: ruleID, occurrenceDate: Date(timeIntervalSinceReferenceDate: timestamp))
    }
}

@MainActor
enum RecurringNotificationResponder {
    static func respond(to action: RecurringNotificationAction, payload: RecurringNotificationPayload) {
        guard case .success(let container) = TrenteContainer.shared else { return }
        _ = try? handle(action, payload: payload, in: container.mainContext)
    }

    @discardableResult
    static func handle(
        _ action: RecurringNotificationAction,
        payload: RecurringNotificationPayload,
        in context: ModelContext
    ) throws -> Bool {
        let ruleID = payload.ruleID
        let descriptor = FetchDescriptor<RecurringTransactionRule>(predicate: #Predicate { rule in rule.id == ruleID })
        guard let rule = try context.fetch(descriptor).first,
              let occurrence = try pendingOccurrence(of: rule, on: payload.occurrenceDate, in: context)
        else { return false }

        switch action {
        case .skip:
            try RecurringTransactionService.shared.skip(occurrence, in: context)
        case .markAsPaid:
            try RecurringTransactionService.shared.confirm(occurrence, in: context)
        }
        return true
    }

    private static func pendingOccurrence(
        of rule: RecurringTransactionRule,
        on date: Date,
        in context: ModelContext
    ) throws -> RecurringTransactionOccurrence? {
        guard let month = try MonthService.shared.month(containing: date, in: context) else { return nil }
        return rule.pendingOccurrences(in: month).first { occurrence in
            Calendar.current.isDate(occurrence.date, inSameDayAs: date)
        }
    }
}
