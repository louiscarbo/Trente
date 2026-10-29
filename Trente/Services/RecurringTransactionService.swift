//
//  RecurringTransactionService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import Foundation
import SwiftData

final class RecurringTransactionService: Sendable {
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
        guard insertTransaction(for: occurrence, in: context, addedDate: addedDate) else { return }
        try context.save()
    }

    @discardableResult
    func confirmDueOccurrences(
        in context: ModelContext,
        now: Date = .now,
        isAutomaticUnlocked: Bool
    ) throws -> Int {
        let rules = try context.fetch(
            FetchDescriptor<RecurringTransactionRule>(predicate: #Predicate { $0.autoConfirm == true })
        )
        guard let earliestCheckpoint = rules.map({ $0.lastAutoConfirmedDate ?? $0.startDate }).min() else { return 0 }

        let firstMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: earliestCheckpoint) ?? earliestCheckpoint
        let months = try context.fetch(
            FetchDescriptor<Month>(predicate: #Predicate { $0.startDate >= firstMonthStart && $0.startDate <= now })
        )
        let dueOccurrences = months.flatMap { month in
            rules.flatMap { $0.dueAutomaticOccurrences(in: month, by: now) }
        }
        guard !dueOccurrences.isEmpty else { return 0 }

        for occurrence in dueOccurrences {
            let rule = occurrence.rule
            rule.lastAutoConfirmedDate = max(rule.lastAutoConfirmedDate ?? .distantPast, occurrence.date)
            if isAutomaticUnlocked {
                insertTransaction(for: occurrence, in: context, addedDate: occurrence.date)
            }
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return isAutomaticUnlocked ? dueOccurrences.count : 0
    }

    @discardableResult
    func insertTransaction(
        for occurrence: RecurringTransactionOccurrence,
        in context: ModelContext,
        addedDate: Date
    ) -> Bool {
        let rule = occurrence.rule
        guard !rule.isSettled(on: occurrence.date) else { return false }

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
        return true
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
