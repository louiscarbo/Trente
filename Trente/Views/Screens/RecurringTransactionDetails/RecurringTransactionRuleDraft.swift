//
//  RecurringTransactionRuleDraft.swift
//  Trente
//

import Foundation

struct RecurringTransactionRuleDraft {
    var title: String
    var frequency: RecurrenceFrequency
    var nextDate: Date
    var endDate: Date?
    var autoConfirm: Bool
    var repartition: [BudgetCategory: Int]
    var repartitionTotalCents: Int
    let hasNextDate: Bool
    private let originalFrequency: RecurrenceFrequency
    private let originalNextDate: Date
    private let originalEndDate: Date?

    init(from rule: RecurringTransactionRule) {
        let today = Calendar.current.startOfDay(for: .now)
        title = rule.title
        frequency = rule.frequency
        let nextPendingDate = rule.nextPendingDate(onOrAfter: today)
        nextDate = nextPendingDate ?? rule.startDate
        hasNextDate = nextPendingDate != nil
        endDate = rule.endDate
        autoConfirm = rule.autoConfirm
        repartition = rule.repartition
        repartitionTotalCents = rule.amountCents
        originalFrequency = rule.frequency
        originalNextDate = nextDate
        originalEndDate = rule.endDate
    }

    var earliestNextDate: Date {
        min(originalNextDate, Calendar.current.startOfDay(for: .now))
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

    func apply(to rule: RecurringTransactionRule) {
        rule.title = title
        if frequency != originalFrequency || nextDate != originalNextDate {
            rule.startDate = nextDate
        }
        rule.frequency = frequency
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
        if nextDate != originalNextDate && nextDate < Calendar.current.startOfDay(for: .now) {
            issues.append(String(localized: "Start date cannot be in the past."))
        }
        let datesChanged = nextDate != originalNextDate || endDate != originalEndDate
        if let endDate, datesChanged, endDate <= nextDate {
            issues.append(String(localized: "End date must be at least 7 days after start date."))
        }
        return issues
    }
}
