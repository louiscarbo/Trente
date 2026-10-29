//
//  GetRemainingBudgetIntent.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import AppIntents
import SwiftUI

struct GetRemainingBudgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Remaining Budget"
    static let description = IntentDescription(
        "Tells you how much is left this month, in total or in one category. The amount is in the month's currency."
    )
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Category", description: "Leave empty for the whole month.")
    var category: BudgetCategory?

    static var parameterSummary: some ParameterSummary {
        Summary("Get what's left in \(\.$category)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog & ShowsSnippetView {
        let remaining = try BudgetIntentService().remaining(
            in: category.map(BudgetScope.category) ?? .all,
            context: TrenteContainer.shared.get().mainContext
        )
        return .result(
            value: remaining.figures.remaining,
            dialog: dialog(for: remaining),
            view: RemainingBudgetSnippetView(
                figures: remaining.figures,
                scope: remaining.scope,
                currencyCode: remaining.currencyCode,
                monthName: remaining.monthName
            )
        )
    }

    private func dialog(for remaining: RemainingBudget) -> IntentDialog {
        let amountText = abs(remaining.figures.remaining).formatted(.budget(remaining.currencyCode))
        switch (remaining.scope, remaining.figures.isOverspent) {
        case (.all, false):
            return "\(amountText) left this month."
        case (.all, true):
            return "\(amountText) over budget this month."
        case (.category, false):
            return "\(amountText) left in \(remaining.scope.name) this month."
        case (.category, true):
            return "\(amountText) over budget in \(remaining.scope.name) this month."
        }
    }
}
