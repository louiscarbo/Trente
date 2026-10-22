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
    init(month: Month) {
        id = month.id
        name = month.name
        currencyCode = month.currency.isoCode
        overall = month.figures(in: .all)
        byCategory = Dictionary(
            uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, month.figures(in: .category($0))) }
        )
        latestTransactions = month.latestTransactions.prefix(3).map(WidgetTransaction.init(group:))
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
}
