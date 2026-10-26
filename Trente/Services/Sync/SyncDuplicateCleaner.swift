//
//  SyncDuplicateCleaner.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData

enum SyncDuplicateCleaner {
    struct OccurrenceKey: Hashable {
        let ruleID: UUID
        let day: Date
    }

    @discardableResult
    static func mergeDuplicates(in context: ModelContext, calendar: Calendar = .current) throws -> Bool {
        let (keptMonths, mergedMonths) = try mergeDuplicateMonths(in: context, calendar: calendar)
        let reattachedOrphans = try reattachOrphanTransactions(to: keptMonths, in: context)
        let removedOccurrences = try removeDuplicateRecurringTransactions(in: context, calendar: calendar)
        guard mergedMonths || reattachedOrphans || removedOccurrences else { return false }
        try context.save()
        return true
    }

    static func keeper<Item>(of duplicates: [Item], modifiedDate: (Item) -> Date?, id: (Item) -> UUID) -> Item? {
        duplicates.max { lhs, rhs in
            let lhsDate = modifiedDate(lhs) ?? .distantPast
            let rhsDate = modifiedDate(rhs) ?? .distantPast
            guard lhsDate == rhsDate else { return lhsDate < rhsDate }
            return id(lhs).uuidString > id(rhs).uuidString
        }
    }

    private static func mergeDuplicateMonths(in context: ModelContext, calendar: Calendar) throws -> (kept: [Month], merged: Bool) {
        let months = try context.fetch(FetchDescriptor<Month>())
        let byStartDay = Dictionary(grouping: months) { month in calendar.startOfDay(for: month.startDate) }
        var keptMonths: [Month] = []
        var merged = false
        for duplicates in byStartDay.values {
            guard let keeper = keeper(of: duplicates, modifiedDate: \.modifiedDate, id: \.id) else { continue }
            keptMonths.append(keeper)
            for duplicate in duplicates where duplicate.id != keeper.id {
                let movedGroups = duplicate.transactionGroups
                duplicate.transactionGroups = []
                for group in movedGroups {
                    group.month = keeper
                }
                context.delete(duplicate)
                merged = true
            }
        }
        return (keptMonths, merged)
    }

    private static func reattachOrphanTransactions(to months: [Month], in context: ModelContext) throws -> Bool {
        let orphans = try context.fetch(FetchDescriptor<TransactionGroup>(predicate: #Predicate { $0.month == nil }))
        var reattached = false
        for orphan in orphans {
            let date = orphan.recurringOccurrenceDate ?? orphan.addedDate
            guard let month = months.first(where: { $0.contains(date) }) else { continue }
            orphan.month = month
            reattached = true
        }
        return reattached
    }

    private static func removeDuplicateRecurringTransactions(in context: ModelContext, calendar: Calendar) throws -> Bool {
        let groups = try context.fetch(FetchDescriptor<TransactionGroup>())
        var byOccurrence: [OccurrenceKey: [TransactionGroup]] = [:]
        for group in groups {
            guard let rule = group.recurringRule, let occurrenceDate = group.recurringOccurrenceDate else { continue }
            byOccurrence[OccurrenceKey(ruleID: rule.id, day: calendar.startOfDay(for: occurrenceDate)), default: []].append(group)
        }
        var removed = false
        for duplicates in byOccurrence.values where duplicates.count > 1 {
            guard let keeper = keeper(of: duplicates, modifiedDate: \.modifiedDate, id: \.id) else { continue }
            for duplicate in duplicates where duplicate.id != keeper.id {
                context.delete(duplicate)
                removed = true
            }
        }
        return removed
    }
}
