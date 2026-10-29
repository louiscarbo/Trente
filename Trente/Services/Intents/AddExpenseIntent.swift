//
//  AddExpenseIntent.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import AppIntents
import WidgetKit

struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Expense"
    static let description = IntentDescription("Adds an expense to the current month in Trente.")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Amount", requestValueDialog: "How much did you spend?")
    var amount: IntentCurrencyAmount

    @Parameter(title: "Title", requestValueDialog: "What was it for?")
    var title: String

    @Parameter(title: "Category", requestValueDialog: "Which category?")
    var category: BudgetCategory

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amount) to \(\.$category)") {
            \.$title
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let added = try BudgetIntentService().addExpense(
            amount: amount.amount,
            title: title,
            category: category,
            in: TrenteContainer.shared.get().mainContext
        )
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: dialog(for: added))
    }

    private func dialog(for added: AddedExpense) -> IntentDialog {
        let remaining = added.remaining
        let amountText = (Double(added.amountCents) / 100).formatted(.amount(remaining.currencyCode))
        let remainingText = abs(remaining.figures.remaining).formatted(.budget(remaining.currencyCode))
        let categoryName = remaining.scope.name
        if remaining.figures.isOverspent {
            return "Added \(amountText) to \(categoryName). \(remainingText) over budget."
        }
        return "Added \(amountText) to \(categoryName). \(remainingText) left."
    }
}
