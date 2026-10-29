//
//  RecurringTransactionRuleDraft.swift
//  Trente
//

import Foundation

struct RecurringTransactionRuleDraft {
    var title: String
    private(set) var frequency: RecurrenceFrequency
    var startDate: Date
    var endDate: Date?
    var autoConfirm: Bool
    var repartition: [BudgetCategory: Int]
    var repartitionTotalCents: Int
    private let originalStartDate: Date
    private let originalEndDate: Date?
    private let nextScheduledDate: Date

    init(from rule: RecurringTransactionRule) {
        title = rule.title
        frequency = rule.frequency
        startDate = rule.startDate
        endDate = rule.endDate
        autoConfirm = rule.autoConfirm
        repartition = rule.repartition
        repartitionTotalCents = rule.amountCents
        originalStartDate = rule.startDate
        originalEndDate = rule.endDate
        let today = Calendar.current.startOfDay(for: .now)
        nextScheduledDate = rule.schedule.firstDate(onOrAfter: today) ?? today
    }

    var expenseCategory: BudgetCategory? {
        get { repartition.keys.first }
        set {
            guard let newValue else { return }
            repartition = [newValue: repartitionTotalCents]
        }
    }

    var expenseAmountCents: Int {
        get { repartitionTotalCents }
        set {
            let signedAmount = -abs(newValue)
            repartitionTotalCents = signedAmount
            if let expenseCategory {
                repartition = [expenseCategory: signedAmount]
            }
        }
    }

    mutating func setFrequency(_ newFrequency: RecurrenceFrequency) {
        frequency = newFrequency
        if startDate < Calendar.current.startOfDay(for: .now) {
            startDate = nextScheduledDate
        }
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
        let datesChanged = startDate != originalStartDate || endDate != originalEndDate
        if let endDate, datesChanged, endDate <= startDate {
            issues.append(String(localized: "End date must be at least 7 days after start date."))
        }
        return issues
    }
}
