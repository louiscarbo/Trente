//
//  WidgetMonth.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 22/10/2026.
//

import Foundation

struct WidgetMonth: Sendable {
    let id: UUID
    let name: String
    let currencyCode: String
    let overall: BudgetFigures
    let byCategory: [BudgetCategory: BudgetFigures]
    let latestTransactions: [WidgetTransaction]

    func figures(for category: BudgetCategory) -> BudgetFigures {
        byCategory[category] ?? BudgetFigures(spent: 0, income: 0, remaining: 0)
    }

    func display(_ amount: Double) -> String {
        amount.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
    }
}

struct WidgetTransaction: Identifiable, Sendable {
    let id: UUID
    let title: String
    let categories: [BudgetCategory]
    let amount: Double
}

extension WidgetMonth {
    init(month: Month, automaticOccurrences: [RecurringTransactionOccurrence] = []) {
        id = month.id
        name = month.name
        currencyCode = month.currency.isoCode
        overall = month.figures(in: .all, including: automaticOccurrences)
        byCategory = Dictionary(
            uniqueKeysWithValues: BudgetCategory.allCases.map { category in
                (category, month.figures(in: .category(category), including: automaticOccurrences))
            }
        )
        let recorded = month.transactionGroups.map { (date: $0.addedDate, transaction: WidgetTransaction(group: $0)) }
        let automatic = automaticOccurrences.map { (date: $0.date, transaction: WidgetTransaction(occurrence: $0)) }
        latestTransactions = (recorded + automatic)
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map(\.transaction)
    }

    static var sample: WidgetMonth {
        WidgetMonth(month: .getSampleMonthWithTransactions())
    }
}

extension WidgetTransaction {
    init(group: TransactionGroup) {
        id = group.id
        title = group.title
        categories = group.entries.map(\.category)
        amount = group.totalAmount
    }

    init(occurrence: RecurringTransactionOccurrence) {
        id = UUID()
        title = occurrence.rule.title
        categories = BudgetCategory.allCases.filter { occurrence.amountCents(in: .category($0)) != 0 }
        amount = Double(occurrence.amountCents) / 100
    }
}
