//
//  SampleData.swift
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
        let schema = Schema([
            Month.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            try insertSampleData()
            
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func insertSampleData() throws {
        for recurringTransactionRule in RecurringTransactionRule.sampleData {
            context.insert(recurringTransactionRule)
        }
        
        for month in Month.sampleData {
            try RecurringTransactionService.shared.refreshInstances(for: month, in: context)

            context.insert(month)
        }
        
        for transaction in TransactionGroup.sampleData(month1: Month.month1, month2: Month.month2) {
            context.insert(transaction)
        }
    }
}

// MARK: Sample Data - Month
extension Month {
    static let month1 = Month(
        startDate: Date(),
        currency: Currencies.currency(for: "EUR")!,
        idealBudgetCents: 3000_00,
        idealRepartition: [
            .needs: 50,
            .wants: 30,
            .savingsAndDebts: 20
        ]
    )
    
    static let month2 = Month(
        startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
        currency: Currencies.currency(for: "EUR")!,
        idealBudgetCents: 600_00,
        idealRepartition: [
            .needs: 50,
            .wants: 30,
            .savingsAndDebts: 20
        ]
    )
    
    static let month3 = Month(
        startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
        currency: Currencies.currency(for: "EUR")!,
        idealBudgetCents: 2_000_00,
        idealRepartition: [
            .needs: 50,
            .wants: 30,
            .savingsAndDebts: 20
        ]
    )
    
    static let month4 = Month(
        startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
        currency: Currencies.currency(for: "EUR")!,
        idealBudgetCents: 1500_00,
        idealRepartition: [
            .needs: 50,
            .wants: 30,
            .savingsAndDebts: 20
        ]
    )
    
    static let sampleData: [Month] = [month1, month2, month3, month4]
    
    static func getSampleMonthWithTransactions() -> Month {
        let month1 = Month(
            startDate: Date(),
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [
                .needs: 50,
                .wants: 30,
                .savingsAndDebts: 20
            ]
        )
        let salary = TransactionGroup(
            title: String(localized: "Salary"),
            type: .income,
            month: month1,
            note: "Monthly paycheck from Trente Inc.",
            imageAttachmentData: nil
        )
        let supermarket = TransactionGroup(
            title: String(localized: "Supermarket"),
            type: .expense,
            month: month1,
            note: "Weekly groceries.",
            imageAttachmentData: nil
        )
        let shopping = TransactionGroup(
            title: String(localized: "Clothes"),
            type: .expense,
            month: month1,
            note: nil,
            imageAttachmentData: nil
        )
        let rent = TransactionGroup(
            title: String(localized: "Rent"),
            type: .expense,
            month: month1,
            note: "Monthly rent payment.",
            imageAttachmentData: nil
        )
        // Set historical date after creation
        rent.addedDate = Date().addingTimeInterval(-3600 * 24 * 10)
        
        supermarket.entries = [
            TransactionEntry(amountCents: -147_18, category: .needs, group: supermarket)
        ]
        shopping.entries = [
            TransactionEntry(amountCents: -119_99, category: .wants, group: shopping)
        ]
        rent.entries = [
            TransactionEntry(amountCents: -720_00, category: .needs, group: rent)
        ]
        salary.entries = [
            TransactionEntry(amountCents: 1600_00, category: .needs, group: salary),
            TransactionEntry(amountCents: 300_00, category: .wants, group: salary),
            TransactionEntry(amountCents: 200_00, category: .savingsAndDebts, group: salary)
        ]
        
        month1.transactionGroups = [supermarket, shopping, rent, salary]
        
        return month1
    }
}

// MARK: Sample Data - RecurringTransactionRule
private extension RecurringTransactionRule {
    /// A few sample recurring rules so that month1, month2 & month3
    /// each get at least two instances when you call `generateInstances(...)`
    static let sampleData: [RecurringTransactionRule] = {
        // Start all rules two months ago, so they fire in month3, month2 & month1
        let start = Month.month3.startDate
        
        // 1) Monthly salary income
        let salary = RecurringTransactionRule(
            title: "Salary",
            frequency: .monthly,
            startDate: start.addingTimeInterval(-15 * 24 * 60 * 60),
            repartition: [
                .needs: 1600_00,
                .wants: 500,
                .savingsAndDebts: 300
            ]
        )
        salary.autoConfirm = true
        
        // 2) Monthly rent expense
        let rent = RecurringTransactionRule(
            title: "Rent",
            frequency: .monthly,
            startDate: start.addingTimeInterval(-1 * 24 * 60 * 60),
            repartition: [
                .needs: -800_00
            ]
        )
        rent.autoConfirm = true
        
        // 3) Weekly coffee expense
        let coffee = RecurringTransactionRule(
            title: "Coffee",
            frequency: .weekly,
            startDate: start.addingTimeInterval(-3 * 24 * 60 * 60),
            repartition: [
                .wants: -300
            ]
        )
        coffee.autoConfirm = true
        
        return [salary, rent, coffee]
    }()
}

// MARK: Sample Data - TransactionGroup
private extension TransactionGroup {
    static func sampleData(month1: Month, month2: Month) -> [TransactionGroup] {
        // Expenses
        let supermarket = TransactionGroup(
            title: "Supermarket",
            type: .expense,
            month: month1,
            note: "Groceries for the first week.",
            imageAttachmentData: nil
        )
        let shopping = TransactionGroup(
            title: "Shopping",
            type: .expense,
            month: month1,
            note: "Summer sale haul.",
            imageAttachmentData: nil
        )
        let livretA = TransactionGroup(
            title: "Livret A",
            type: .expense,
            month: month1,
            note: "Monthly savings deposit.",
            imageAttachmentData: nil
        )
        let rent = TransactionGroup(
            title: "Rent",
            type: .expense,
            month: month2,
            note: "Rent for the previous month.",
            imageAttachmentData: nil
        )
        // Set historical date after creation
        rent.addedDate = Date().addingTimeInterval(-3600 * 24 * 10)

        supermarket.entries = [
            TransactionEntry(amountCents: -150_00, category: .needs, group: supermarket)
        ]
        shopping.entries = [
            TransactionEntry(amountCents: -120_00, category: .wants, group: shopping)
        ]
        livretA.entries = [
            TransactionEntry(amountCents: -100_00, category: .savingsAndDebts, group: livretA)
        ]
        rent.entries = [
            TransactionEntry(amountCents: -800_00, category: .needs, group: rent)
        ]

        // Income (grouped under one transaction group)
        let salary = TransactionGroup(
            title: "Salary",
            type: .income,
            month: month1,
            note: "July Paycheck.",
            imageAttachmentData: nil
        )

        salary.entries = [
            TransactionEntry(amountCents: 540_00, category: .needs, group: salary),
            TransactionEntry(amountCents: 300_00, category: .wants, group: salary),
            TransactionEntry(amountCents: 200_00, category: .savingsAndDebts, group: salary)
        ]

        return [supermarket, shopping, livretA, salary, rent]
    }
}
