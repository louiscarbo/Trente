//
//  Month.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    final class Month: Identifiable, Hashable, Equatable {
        var id: UUID = UUID()
        var startDate: Date = Date.now
        var modifiedDate: Date?
        var currency: Currency = Currency.fallback

        var idealBudgetCents: Int = 0
        var idealRepartition: [BudgetCategory: Int] = [:]

        @Relationship(deleteRule: .nullify, inverse: \TransactionGroup.month)
        var storedTransactionGroups: [TransactionGroup]? = []

        init(startDate: Date, currency: Currency, idealBudgetCents: Int, idealRepartition: [BudgetCategory: Int]) {
            self.startDate = startDate
            self.currency = currency
            self.idealBudgetCents = idealBudgetCents
            self.idealRepartition = idealRepartition
        }
    }
}

extension Month {
    var transactionGroups: [TransactionGroup] {
        get { storedTransactionGroups ?? [] }
        set { storedTransactionGroups = newValue }
    }
}

enum BudgetScope: Hashable {
    case all
    case category(BudgetCategory)
}

struct BudgetFigures: Hashable, Sendable {
    let spent: Double
    let income: Double
    let remaining: Double

    var isOverspent: Bool {
        remaining < 0
    }
}

// MARK: - Computed Properties
extension Month {
    var name: String {
        Month.name(startingOn: startDate)
    }

    static func name(startingOn startDate: Date) -> String {
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

    private var incomeAmountCents: Int {
        transactionEntries.filter { $0.amountCents > 0 }.reduce(0) { $0 + $1.amountCents }
    }

    /// A localized string that displays the spent amount for the month in entire value, truncating the cents.
    var spentAmountDisplay: String {
        let amount = spentAmount
        return amount.formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }

    var remainingAmount: Double {
        Double(remainingAmountCents) / 100
    }

    var incomeAmount: Double {
        Double(incomeAmountCents) / 100
    }

    var incomeAmountDisplay: String {
        return incomeAmount.formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }

    /// A localized string that displays the remaining amount for the month in entire value, truncating the cents.
    var remainingAmountDisplay: String {
        return remainingAmount.formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }

    var negativeSpentAmount: Double {
        Double(spentAmountCents) / 100
    }

    var overSpent: Bool {
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

    func spentAmount(in scope: BudgetScope) -> Double {
        switch scope {
        case .all: abs(negativeSpentAmount)
        case .category(let category): spentAmount(for: category)
        }
    }

    func spentAmountDisplay(in scope: BudgetScope) -> String {
        spentAmount(in: scope).formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }

    func remainingAmountDisplay(in scope: BudgetScope) -> String {
        remainingAmount(in: scope).formatted(.currency(code: currency.isoCode).precision(.fractionLength(0)))
    }

    func incomeAmount(in scope: BudgetScope) -> Double {
        switch scope {
        case .all: incomeAmount
        case .category(let category): incomeAmount(for: category)
        }
    }

    func remainingAmount(in scope: BudgetScope) -> Double {
        switch scope {
        case .all: remainingAmount
        case .category(let category): remainingAmount(for: category)
        }
    }

    func overSpending(in scope: BudgetScope) -> Bool {
        remainingAmount(in: scope) < 0
    }

    func figures(in scope: BudgetScope) -> BudgetFigures {
        BudgetFigures(
            spent: spentAmount(in: scope),
            income: incomeAmount(in: scope),
            remaining: remainingAmount(in: scope)
        )
    }

    func figures(in scope: BudgetScope, including occurrences: [RecurringTransactionOccurrence]) -> BudgetFigures {
        occurrences.reduce(figures(in: scope)) { figures, occurrence in
            let amount = Double(occurrence.amountCents(in: scope)) / 100
            return BudgetFigures(
                spent: figures.spent + max(0, -amount),
                income: figures.income + max(0, amount),
                remaining: figures.remaining + amount
            )
        }
    }

    func endDate() -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: dateInterval.end)!
    }

    var dateInterval: DateInterval {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }

    func contains(_ date: Date) -> Bool {
        let interval = dateInterval
        return interval.start <= date && date < interval.end
    }

    var latestTransactions: [TransactionGroup] {
        transactionGroups.sorted(by: { $0.addedDate > $1.addedDate })
    }
}
