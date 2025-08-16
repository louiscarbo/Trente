//
//  MonthDraft.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 13/08/2025.
//

import Foundation

struct MonthDraft: Equatable {
    var startDate: Date
    var currency: Currency
    var idealBudgetCents: Int
    var idealRepartition: [BudgetCategory: Int]

    init(from month: Month) {
        self.startDate = month.startDate
        self.currency = month.currency
        self.idealBudgetCents = month.idealBudgetCents
        self.idealRepartition = month.idealRepartition
    }

    init(startDate: Date, currency: Currency, idealBudgetCents: Int, idealRepartition: [BudgetCategory: Int]) {
        self.startDate = startDate
        self.currency = currency
        self.idealBudgetCents = idealBudgetCents
        self.idealRepartition = idealRepartition
    }

    func apply(to month: Month) {
        month.startDate = startDate
        month.currency = currency
        month.idealBudgetCents = idealBudgetCents
        month.idealRepartition = idealRepartition
    }

    func makeMonth() -> Month {
        Month(
            startDate: startDate,
            currency: currency,
            idealBudgetCents: idealBudgetCents,
            idealRepartition: idealRepartition
        )
    }
}

enum MonthFormatting {
    static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static func name(from startDate: Date) -> String {
        monthYearFormatter.string(from: startDate).capitalized
    }
}
