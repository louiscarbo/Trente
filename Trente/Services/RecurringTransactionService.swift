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
    
    // TODO: MAKE IT THROW
    func fetchRecurringTransactionsCount(from model: ModelContext) -> Int {
        let descriptor = FetchDescriptor<RecurringTransactionInstance>()
        do {
            let groupsCount = try model.fetchCount(descriptor)
            return groupsCount
        } catch {
            print("⚠️ fetchTransactionsCount failed:", error)
            return 0
        }
    }
}
