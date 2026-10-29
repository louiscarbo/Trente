//
//  BudgetIntentService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Foundation
import SwiftData

enum BudgetIntentError: Error, Equatable, CustomLocalizedStringResourceConvertible {
    case noMonth
    case invalidAmount
    case missingTitle

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noMonth:
            "Open Trente to create your first month."
        case .invalidAmount:
            "The amount must be more than zero."
        case .missingTitle:
            "Give the expense a title."
        }
    }
}

struct RemainingBudget: Equatable {
    let scope: BudgetScope
    let figures: BudgetFigures
    let currencyCode: String
    let monthName: String
}

struct AddedExpense: Equatable {
    let amountCents: Int
    let remaining: RemainingBudget
}

@MainActor
struct BudgetIntentService {
    func currentMonth(in context: ModelContext, now: Date = .now) throws -> Month {
        try CatchUpService.shared.catchUp(in: context, now: now)
        let month = try MonthService.shared.month(containing: now, in: context) ?? MonthService.shared.latestMonth(in: context)
        guard let month else {
            throw BudgetIntentError.noMonth
        }
        return month
    }

    func addExpense(
        amount: Decimal,
        title: String,
        category: BudgetCategory,
        in context: ModelContext,
        now: Date = .now
    ) throws -> AddedExpense {
        guard let cents = Self.cents(from: amount) else {
            throw BudgetIntentError.invalidAmount
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw BudgetIntentError.missingTitle
        }

        let month = try currentMonth(in: context, now: now)
        let request = TransactionCreationRequest()
        request.type = .expense
        request.title = trimmedTitle
        request.amountCents = cents
        request.selectedCategory = category
        request.date = now
        try TransactionService.shared.create(with: request, for: month, in: context)

        return AddedExpense(
            amountCents: cents,
            remaining: remaining(in: .category(category), of: month)
        )
    }

    func remaining(in scope: BudgetScope, context: ModelContext, now: Date = .now) throws -> RemainingBudget {
        remaining(in: scope, of: try currentMonth(in: context, now: now))
    }

    static func cents(from amount: Decimal) -> Int? {
        var scaled = amount * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        let cents = NSDecimalNumber(decimal: rounded)
        guard cents.compare(NSDecimalNumber(value: Int.max)) == .orderedAscending else { return nil }
        let value = cents.intValue
        return value > 0 ? value : nil
    }

    private func remaining(in scope: BudgetScope, of month: Month) -> RemainingBudget {
        RemainingBudget(
            scope: scope,
            figures: month.figures(in: scope),
            currencyCode: month.currency.isoCode,
            monthName: month.name
        )
    }
}
