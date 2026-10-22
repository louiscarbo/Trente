//
//  DataProvider.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData

@MainActor
class DataProvider {
    static let shared = DataProvider()
    
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    private init() {
        let modelConfiguration = ModelConfiguration(schema: .trente, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self, configurations: [modelConfiguration])
            
            try insertSampleData()
            
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func insertSampleData() throws {
        let rules = RecurringTransactionRule.sampleData
        for rule in rules {
            context.insert(rule)
        }

        for month in Month.sampleData {
            context.insert(month)
            linkRecurringTransactions(of: month, to: rules)
        }
    }

    private func linkRecurringTransactions(of month: Month, to rules: [RecurringTransactionRule]) {
        for group in month.transactionGroups {
            guard let rule = rules.first(where: { $0.title == group.title }) else { continue }
            group.recurringRule = rule
            group.recurringOccurrenceDate = group.addedDate
        }
    }
}
