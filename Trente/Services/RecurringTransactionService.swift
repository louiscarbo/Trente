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

    func delete(rule: RecurringTransactionRule, in context: ModelContext) {
        // The cascade delete rule on instances removes all pending instances automatically.
        // Confirmed instances' linked TransactionGroups are kept as standalone transactions.
        context.delete(rule)
    }

    /// Refreshes instances for a single rule across all months it spans.
    /// Only unconfirmed instances are replaced; confirmed ones (linked to a TransactionGroup) are preserved.
    /// If the rule has autoConfirm enabled, past-due instances are materialized after refresh.
    func refreshInstances(for rule: RecurringTransactionRule, in context: ModelContext) throws {
        let unconfirmed = rule.instances.filter { !$0.confirmed }
        unconfirmed.forEach { context.delete($0) }

        let ruleEnd = rule.endDate ?? Date.distantFuture
        let predicate = #Predicate<Month> { $0.startDate <= ruleEnd }
        let allMonths = try context.fetch(FetchDescriptor<Month>(predicate: predicate))
        let affected = allMonths.filter { $0.endDate() >= rule.startDate }

        let confirmedDates = Set(rule.instances.filter { $0.confirmed }.map { $0.date })
        for month in affected {
            rule.createRecurringInstances(for: month)
                .filter { !confirmedDates.contains($0.date) }
                .forEach { context.insert($0) }
        }
        try context.save()

        if rule.autoConfirm {
            try autoConfirmDueInstances(asOf: .now, in: context)
        }
    }

    /// Regenerates all unconfirmed instances for the given month across all active rules.
    func refreshInstances(for month: Month, in context: ModelContext) throws {
        let startOfMonth = month.startDate
        let endOfMonth = month.endDate()

        let predicate = #Predicate<RecurringTransactionInstance> {
            $0.date >= startOfMonth && $0.date <= endOfMonth
        }

        let fetchDescriptor = FetchDescriptor<RecurringTransactionInstance>(predicate: predicate)
        let instancesToDelete = try context.fetch(fetchDescriptor)

        for instance in instancesToDelete {
            context.delete(instance)
        }

        try generateInstances(for: month, in: context)
    }

    /// Creates a TransactionGroup for the given instance, optionally applying per-occurrence overrides.
    /// Idempotent: if the instance already has a linked group, returns it without further changes.
    @discardableResult
    func materialize(
        instance: RecurringTransactionInstance,
        overrides: RecurringInstanceOverrides? = nil,
        in context: ModelContext
    ) throws -> TransactionGroup {
        if let existing = instance.transactionGroup {
            return existing
        }

        let effectiveRepartition = overrides?.repartition ?? instance.rule.repartition
        let hasPositive = effectiveRepartition.values.contains { $0 > 0 }
        let effectiveType = overrides?.type ?? (hasPositive ? .income : .expense)
        let effectiveTitle = overrides?.title ?? instance.rule.title

        let group = TransactionGroup(
            title: effectiveTitle,
            type: effectiveType,
            month: instance.month,
            note: overrides?.notes,
            imageAttachmentData: overrides?.imageData
        )
        context.insert(group)

        for (category, amount) in effectiveRepartition where amount != 0 {
            if effectiveType == .income, amount <= 0 { continue }
            let entry = TransactionEntry(amountCents: amount, category: category, group: group)
            context.insert(entry)
        }

        instance.transactionGroup = group
        return group
    }

    /// Validates a pending recurring instance: materializes it and saves.
    func validate(instance: RecurringTransactionInstance, in context: ModelContext) throws {
        try materialize(instance: instance, overrides: nil, in: context)
        try context.save()
    }

    /// Validates a pending recurring instance with per-occurrence overrides.
    func validate(
        instance: RecurringTransactionInstance,
        withOverrides overrides: RecurringInstanceOverrides,
        in context: ModelContext
    ) throws {
        try materialize(instance: instance, overrides: overrides, in: context)
        try context.save()
    }

    /// Materializes all unconfirmed instances dated on or before the end of today,
    /// for any rule with autoConfirm = true. Returns the number confirmed.
    @discardableResult
    func autoConfirmDueInstances(asOf now: Date = .now, in context: ModelContext) throws -> Int {
        let cutoff = Calendar.current.startOfDay(for: now).addingTimeInterval(86_399)
        let descriptor = FetchDescriptor<RecurringTransactionInstance>(
            predicate: #Predicate { $0.date <= cutoff }
        )
        let candidates = try context.fetch(descriptor)
        let toConfirm = candidates.filter { $0.transactionGroup == nil && $0.rule.autoConfirm }

        for instance in toConfirm {
            try materialize(instance: instance, overrides: nil, in: context)
        }

        if !toConfirm.isEmpty {
            try context.save()
        }

        return toConfirm.count
    }
}

private extension RecurringTransactionService {
    /// Fetches all rules whose window overlaps the given month,
    /// asks each rule to build its instances, then persists them all in one save.
    func generateInstances(for month: Month, in context: ModelContext) throws {
        let startOfMonth = month.startDate
        let endOfMonth   = month.endDate()

        let farFuture = Date.distantFuture

        let predicate = #Predicate<RecurringTransactionRule> {
            $0.startDate <= endOfMonth &&
            ($0.endDate ?? farFuture) >= startOfMonth
        }

        let fetchDesc = FetchDescriptor<RecurringTransactionRule>(predicate: predicate)
        let rules = try context.fetch(fetchDesc)

        var newInstances: [RecurringTransactionInstance] = []
        for rule in rules {
            let instances = rule.createRecurringInstances(for: month)
            newInstances.append(contentsOf: instances)
        }

        newInstances.forEach { context.insert($0) }
        try context.save()
    }
}
