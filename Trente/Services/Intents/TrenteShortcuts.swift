//
//  TrenteShortcuts.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import AppIntents

struct TrenteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "Add an expense to \(.applicationName)",
                "Log an expense in \(.applicationName)",
                "Add an expense to \(\.$category) in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: GetRemainingBudgetIntent(),
            phrases: [
                "How much is left in \(.applicationName)",
                "What's left in \(.applicationName)",
                "Show my remaining budget in \(.applicationName)",
                "How much is left in \(\.$category) in \(.applicationName)"
            ],
            shortTitle: "Remaining Budget",
            systemImageName: "gauge.with.dots.needle.50percent"
        )
    }
}
