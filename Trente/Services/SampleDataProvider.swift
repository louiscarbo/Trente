//
//  SampleData.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData

@MainActor
class SampleDataProvider {
    static let shared = SampleDataProvider()
    
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    private init() {
        let schema = Schema([
            Month.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            insertSampleData()
            
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func insertSampleData() {
        for recurringTransactionRule in RecurringTransactionRule.sampleData {
            context.insert(recurringTransactionRule)
        }
        
        for month in Month.sampleData {
            do {
                try RecurringTransactionService.shared.generateInstances(for: month, in: context)
            } catch {
                print("Error generating instances for month \(month): \(error)")
            }

            context.insert(month)
        }
        
        for transaction in TransactionGroup.sampleData(month1: Month.month1, month2: Month.month2) {
            context.insert(transaction)
        }
    }
}
