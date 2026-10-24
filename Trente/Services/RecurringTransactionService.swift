//
//  RecurringTransactionService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import Foundation
import SwiftData

final class RecurringTransactionService {
    static let shared = RecurringTransactionService()
    private init() {}

    func pendingOccurrences(of rules: [RecurringTransactionRule], in month: Month) -> [RecurringTransactionOccurrence] {
        rules
            .flatMap { $0.pendingOccurrences(in: month) }
            .sorted { $0.date < $1.date }
    }

    func confirm(
        _ occurrence: RecurringTransactionOccurrence,
        in context: ModelContext,
        addedDate: Date = .now
    ) throws {
        let rule = occurrence.rule
        guard !rule.isSettled(on: occurrence.date) else { return }

        let group = TransactionGroup(
            title: rule.title,
            type: occurrence.amountCents < 0 ? .expense : .income,
            month: occurrence.month,
            note: nil,
            imageAttachmentData: nil,
            addedDate: addedDate
        )
        context.insert(group)
        group.recurringRule = rule
        group.recurringOccurrenceDate = occurrence.date

        let entries = BudgetCategory.allCases.compactMap { category -> TransactionEntry? in
            guard let amount = rule.repartition[category], amount != 0 else { return nil }
            return TransactionEntry(amountCents: amount, category: category, group: group)
        }
        entries.forEach { context.insert($0) }
        group.entries = entries

        occurrence.month.transactionGroups.append(group)
        try context.save()
    }

    @discardableResult
    func confirmDueOccurrences(in context: ModelContext, now: Date = .now) throws -> Int {
        let rules = try context.fetch(
            FetchDescriptor<RecurringTransactionRule>(predicate: #Predicate { $0.autoConfirm == true })
        )
        guard !rules.isEmpty else { return 0 }

        let months = try context.fetch(FetchDescriptor<Month>())
        let dueOccurrences = months.flatMap { month in
            rules.flatMap { $0.dueAutomaticOccurrences(in: month, by: now) }
        }
        for occurrence in dueOccurrences {
            let rule = occurrence.rule
            rule.lastAutoConfirmedDate = max(rule.lastAutoConfirmedDate ?? .distantPast, occurrence.date)
            try confirm(occurrence, in: context, addedDate: occurrence.date)
        }
        return dueOccurrences.count
    }

    func skip(_ occurrence: RecurringTransactionOccurrence, in context: ModelContext) throws {
        try skip(occurrence.rule, on: occurrence.date, in: context)
    }

    func skip(_ rule: RecurringTransactionRule, on date: Date, in context: ModelContext) throws {
        guard !rule.isSkipped(on: date) else { return }
        rule.skippedOccurrenceDates.append(date)
        try context.save()
    }

    func stop(_ rule: RecurringTransactionRule, in context: ModelContext) throws {
        rule.endDate = Calendar.current.startOfDay(for: .now)
        try context.save()
    }

    func delete(rule: RecurringTransactionRule, in context: ModelContext) {
        context.delete(rule)
    }
}
