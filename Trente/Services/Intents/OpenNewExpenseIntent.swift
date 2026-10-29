//
//  OpenNewExpenseIntent.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import AppIntents

struct OpenNewExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "New Expense"
    static let description = IntentDescription("Opens Trente on a new expense.")
    static let supportedModes: IntentModes = .foreground(.immediate)

    @MainActor
    func perform() async throws -> some IntentResult {
        NewExpenseRouter.shared.isRequested = true
        return .result()
    }
}
