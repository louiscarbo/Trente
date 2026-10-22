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

    func confirm(_ occurrence: RecurringTransactionOccurrence, in context: ModelContext) throws {
        let rule = occurrence.rule
        guard !rule.isSettled(on: occurrence.date) else { return }

        let group = TransactionGroup(
            title: rule.title,
            type: occurrence.amountCents < 0 ? .expense : .income,
            month: occurrence.month,
            note: nil,
            imageAttachmentData: nil
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

    func skip(_ occurrence: RecurringTransactionOccurrence, in context: ModelContext) throws {
        let rule = occurrence.rule
        guard !rule.isSkipped(on: occurrence.date) else { return }
        rule.skippedOccurrenceDates.append(occurrence.date)
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
