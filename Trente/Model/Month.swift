//
//  Month.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData

@Model
final class Month : Identifiable, Hashable, Equatable {
    var id: UUID = UUID()
    var startDate: Date
    var availableIncomeCents: Int
    var currency: Currency
    
    var categoryRepartition: [BudgetCategory: Int] // Amount in cents for each category

    @Relationship(deleteRule: .cascade, inverse: \TransactionGroup.month)
    var transactionGroups: [TransactionGroup] = []

    @Relationship(deleteRule: .cascade, inverse: \RecurringTransactionInstance.month)
    var recurringTransactionInstances: [RecurringTransactionInstance] = []

    var isDeleted: Bool = false
    
    init(startDate: Date, availableIncomeCents: Int, currency: Currency, categoryRepartition: [BudgetCategory: Int]) {
        self.startDate = startDate
        self.availableIncomeCents = availableIncomeCents
        self.currency = currency
        self.categoryRepartition = categoryRepartition
    }
}

// MARK: - Computed Properties
extension Month {
    var name: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: startDate).capitalized
    }
    
    private var transactionEntries: [TransactionEntry] {
        transactionGroups.flatMap { $0.entries }
    }
        
    private var remainingAmountCents: Int {
        transactionEntries.reduce(0) { $0 + $1.amountCents }
    }
    
    private var spentAmountCents: Int {
        transactionEntries.filter { $0.amountCents < 0 }.reduce(0) { $0 + $1.amountCents }
    }
    
    private var spentAmount: Double {
        Double(spentAmountCents) / 100
    }
    
    /// A localized string that displays the spent amount for the month in entire value, truncating the cents.
    var spentAmountDisplay: String {
        let amount = spentAmount
        return amount.formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }
    
    var remainingAmount: Double {
        Double(remainingAmountCents) / 100
    }
    
    /// A localized string that displays the remaining amount for the month in entire value, truncating the cents.
    var remainingAmountDisplay: String {
        let amount = remainingAmount
        return amount.formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }
    
    var negativeSpentAmount: Double {
        Double(spentAmountCents) / 100
    }
    
    var overSpent : Bool {
        remainingAmountCents < 0
    }
    
    /// Calculates the remaining budget for a specific category. Not in cents, positive value.
    func spentAmount(for category: BudgetCategory) -> Double {
        let categoryTransactions = transactionEntries.filter { $0.category == category && $0.amountCents < 0 }
        let categoryRemainingAmount = categoryTransactions.reduce(0) { $0 + $1.amountCents }
        return abs(Double(categoryRemainingAmount) / 100)
    }
    
    /// Returns a localized string that displays the spent amount for a category in entire value, truncating the cents.
    func spentAmountDisplay(for category: BudgetCategory) -> String {
        let amount = spentAmount(for: category)
        return amount.formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }
    
    /// Calculates the sum of incomes for a specific category. Not in cents.
    func incomeAmount(for category: BudgetCategory) -> Double {
        let categoryTransactions = transactionEntries.filter { $0.category == category && $0.amountCents > 0 }
        let categoryIncomeAmount = categoryTransactions.reduce(0) { $0 + $1.amountCents }
        return Double(categoryIncomeAmount) / 100
    }
    
    /// Calculates the budget that is remaining for a specific category. Not in cents.
    func remainingAmount(for category: BudgetCategory) -> Double {
        return (incomeAmount(for: category) - spentAmount(for: category))
    }
    
    /// Returns a localized string that displays the remaining amount for a category in entire value, truncating the cents.
    func remainingAmountDisplay(for category: BudgetCategory) -> String {
        let amount = remainingAmount(for: category)
        return amount.formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }
    
    /// Returns true if the user is overspending in a specific category
    func overSpending(in category: BudgetCategory) -> Bool {
        remainingAmount(for: category) < 0
    }
    
    /// Returns the end date of the month. Adding 1 month to startDate and subtracting 1 day.
    func endDate() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: startDate)
        components.month! += 1
        components.day! -= 1
        return calendar.date(from: components)!
    }
    
    var latestTransactions: [TransactionGroup] {
        transactionGroups.sorted(by: { $0.addedDate > $1.addedDate })
    }
}

extension Month {
    func detachedCopy() -> Month {
        let copy = Month(
            startDate: startDate,
            availableIncomeCents: availableIncomeCents,
            currency: currency,
            categoryRepartition: categoryRepartition
        )
        
        copy.transactionGroups = transactionGroups.map { $0.detachedCopy() }
        copy.recurringTransactionInstances = recurringTransactionInstances.map { $0.detachedCopy() }
        
        return copy
    }
}

// MARK: - Sample Data
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
    
    static let sampleData: [Month] = [
        month1,
        month2,
        month3,
        month4
    ]
}
