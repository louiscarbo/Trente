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
    func refreshInstances(for rule: RecurringTransactionRule, in context: ModelContext) throws {
        let unconfirmed = rule.instances.filter { !$0.confirmed }
        unconfirmed.forEach { context.delete($0) }

        let allMonths = try context.fetch(FetchDescriptor<Month>())
        let ruleEnd = rule.endDate ?? Date.distantFuture
        let affected = allMonths.filter { $0.startDate <= ruleEnd && $0.endDate() >= rule.startDate }

        let confirmedDates = Set(rule.instances.filter { $0.confirmed }.map { $0.date })
        for month in affected {
            rule.createRecurringInstances(for: month)
                .filter { !confirmedDates.contains($0.date) }
                .forEach { context.insert($0) }
        }
        try context.save()
    }

    /// Deletes all previous stored TransactionInstances for this month, then generates them using
    /// generateInstances.
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

        let fetchDesc = FetchDescriptor<RecurringTransactionRule>(
            predicate: predicate
        )
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
