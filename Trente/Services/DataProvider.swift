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
            try RecurringTransactionService.shared.generateInstances(for: month, in: context)

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
        availableIncomeCents: 1600_00,
        currency: Currencies.currency(for: "EUR")!,
        categoryRepartition: [
            .needs: 50,
            .wants: 30,
            .savingsAndDebts: 20
        ]
    )
    
    static let month2 = Month(
        startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
        availableIncomeCents: 1600_00,
        currency: Currencies.currency(for: "EUR")!,
        categoryRepartition: [
            .needs: 50,
            .wants: 30,
            .savingsAndDebts: 20
        ]
    )
    
    static let month3 = Month(
        startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
        availableIncomeCents: 1600_00,
        currency: Currencies.currency(for: "EUR")!,
        categoryRepartition: [
            .needs: 50,
            .wants: 30,
            .savingsAndDebts: 20
        ]
    )
    
    static let month4 = Month(
        startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
        availableIncomeCents: 1600_00,
        currency: Currencies.currency(for: "EUR")!,
        categoryRepartition: [
            .needs: 50,
            .wants: 30,
            .savingsAndDebts: 20
        ]
    )
    
    static let sampleData: [Month] = [month1, month2, month3, month4]
    
    static func getSampleMonthWithTransactions() -> Month {
        let month1 = Month(
            startDate: Date(),
            availableIncomeCents: 1600_00,
            currency: Currencies.currency(for: "EUR")!,
            categoryRepartition: [
                .needs: 50,
                .wants: 30,
                .savingsAndDebts: 20
            ]
        )
        let salary = TransactionGroup(
            addedDate: Date(),
            title: String(localized: "Salary"),
            type: .income,
            month: month1
        )
        let supermarket = TransactionGroup(
            addedDate: Date(),
            title: String(localized: "Supermarket"),
            type: .expense,
            month: month1
        )
        let shopping = TransactionGroup(
            addedDate: Date(),
            title: String(localized: "Clothes"),
            type: .expense,
            month: month1
        )
        let rent = TransactionGroup(
            addedDate: Date().addingTimeInterval(-3600 * 24 * 10),
            title: String(localized: "Rent"),
            type: .expense,
            month: month1
        )
        
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
            addedDate: Date(),
            title: "Supermarket",
            type: .expense,
            month: month1
        )
        let shopping = TransactionGroup(
            addedDate: Date(),
            title: "Shopping",
            type: .expense,
            month: month1
        )
        let livretA = TransactionGroup(
            addedDate: Date(),
            title: "Livret A",
            type: .expense,
            month: month1
        )
        let rent = TransactionGroup(
            addedDate: Date().addingTimeInterval(-3600 * 24 * 10),
            title: "Rent",
            type: .expense,
            month: month2
        )

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
            addedDate: Date(),
            title: "Salary",
            type: .income,
            month: month1
        )

        salary.entries = [
            TransactionEntry(amountCents: 540_00, category: .needs, group: salary),
            TransactionEntry(amountCents: 300_00, category: .wants, group: salary),
            TransactionEntry(amountCents: 200_00, category: .savingsAndDebts, group: salary)
        ]

        return [supermarket, shopping, livretA, salary, rent]
    }
}
