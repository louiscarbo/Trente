//
//  BatchDeleteService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 30/10/2026.
//

import Foundation
import SwiftData

final class BatchDeleteService: Sendable {
    typealias Save = (ModelContext) throws -> Void

    static let shared = BatchDeleteService()
    private init() {}

    func delete(
        groups: [TransactionGroup],
        in context: ModelContext,
        save: Save = { try $0.save() }
    ) throws {
        loadEntriesForRollback(of: groups)
        try commit(groups, in: context, save: save) { group in
            TransactionService.shared.delete(group: group, in: context)
        }
    }

    func delete(
        rules: [RecurringTransactionRule],
        in context: ModelContext,
        save: Save = { try $0.save() }
    ) throws {
        try commit(rules, in: context, save: save) { rule in
            RecurringTransactionService.shared.delete(rule: rule, in: context)
        }
    }

    func delete(
        months: [Month],
        in context: ModelContext,
        save: Save = { try $0.save() }
    ) throws {
        let latestMonth = try MonthService.shared.latestMonth(in: context)
        let archivedMonths = months.filter { month in month != latestMonth }
        loadEntriesForRollback(of: archivedMonths.flatMap(\.transactionGroups))
        try commit(archivedMonths, in: context, save: save) { month in
            MonthService.shared.delete(month: month, in: context)
        }
    }

    private func loadEntriesForRollback(of groups: [TransactionGroup]) {
        for group in groups {
            _ = group.entries.map(\.amountCents)
        }
    }

    private func commit<Item>(
        _ items: [Item],
        in context: ModelContext,
        save: Save,
        deleting deleteItem: (Item) -> Void
    ) throws {
        guard !items.isEmpty else { return }
        items.forEach(deleteItem)
        do {
            try save(context)
        } catch {
            context.rollback()
            throw error
        }
    }
}
