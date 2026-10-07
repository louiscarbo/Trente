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
            modelContainer = try ModelContainer(for: .trente, configurations: [modelConfiguration])
            
            try insertSampleData()
            
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func insertSampleData() throws {
        for rule in RecurringTransactionRule.sampleData {
            context.insert(rule)
        }

        for month in Month.sampleData {
            context.insert(month)
            try RecurringTransactionService.shared.refreshInstances(for: month, in: context)
            linkRecurringInstancesToTransactions(of: month)
        }
    }

    private func linkRecurringInstancesToTransactions(of month: Month) {
        for instance in month.recurringTransactionInstances {
            instance.transactionGroup = month.transactionGroups.first { $0.title == instance.rule.title }
        }
    }
}
