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
    
    // TODO: Refactor the 2 functions here to share more code/logic (or eventually make the whole logic more robust)
    // For example, we could imagine an equivalent of this function but that would work on a per-rule basis.
    // This way, when adding a new rule, we could generate/refresh the instances only for this rule and leave the other
    // rules as they are. To be thought lol.
    
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
        // Compute month bounds
        let startOfMonth = month.startDate
        let endOfMonth   = month.endDate()
        
        // Treat nil endDate as Date.distantFuture so ($0.endDate ?? farFuture) >= startOfMonth
        let farFuture = Date.distantFuture

        // Predicate: rule.startDate ≤ endOfMonth AND (rule.endDate is nil ⇒ farFuture) ≥ startOfMonth
        let predicate = #Predicate<RecurringTransactionRule> {
            $0.startDate <= endOfMonth &&
            ($0.endDate ?? farFuture) >= startOfMonth
        }

        // Fetch all relevant rules
        let fetchDesc = FetchDescriptor<RecurringTransactionRule>(
            predicate: predicate
        )
        let rules = try context.fetch(fetchDesc)

        // Generate instances
        var newInstances: [RecurringTransactionInstance] = []
        for rule in rules {
            let instances = rule.createRecurringInstances(for: month)
            newInstances.append(contentsOf: instances)
        }

        // Persist them all at once
        newInstances.forEach { context.insert($0) }
        try context.save()
    }

}
