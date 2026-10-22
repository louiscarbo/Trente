//
//  RecurringTransactionRuleDraft.swift
//  Trente
//

import Foundation

struct RecurringTransactionRuleDraft {
    var title: String
    var frequency: RecurrenceFrequency
    var startDate: Date
    var endDate: Date?
    var autoConfirm: Bool
    var repartition: [BudgetCategory: Int]
    var repartitionTotalCents: Int
    private let originalStartDate: Date

    init(from rule: RecurringTransactionRule) {
        title = rule.title
        frequency = rule.frequency
        startDate = rule.startDate
        endDate = rule.endDate
        autoConfirm = rule.autoConfirm
        repartition = rule.repartition
        repartitionTotalCents = rule.repartition.values.reduce(0, +)
        originalStartDate = rule.startDate
    }

    func apply(to rule: RecurringTransactionRule) {
        rule.title = title
        rule.frequency = frequency
        rule.startDate = startDate
        rule.endDate = endDate
        rule.autoConfirm = autoConfirm
        rule.setRepartition(repartition)
    }

    func validate() -> [String] {
        var issues: [String] = []
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(String(localized: "Title cannot be empty."))
        }
        let total = repartition.values.reduce(0, +)
        if total == 0 {
            issues.append(String(localized: "At least one category must have a non-zero amount."))
        }
        if total != repartitionTotalCents && repartitionTotalCents != 0 {
            issues.append(String(localized: "Repartition total does not match the amount to split."))
        }
        if startDate != originalStartDate && startDate < Calendar.current.startOfDay(for: .now) {
            issues.append(String(localized: "Start date cannot be in the past."))
        }
        if let endDate, endDate <= startDate {
            issues.append(String(localized: "End date must be at least 7 days after start date."))
        }
        return issues
    }
}
