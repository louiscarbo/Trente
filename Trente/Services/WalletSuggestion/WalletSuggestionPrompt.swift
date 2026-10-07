//
//  WalletSuggestionPrompt.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

enum WalletSuggestionPrompt {
    static let instructions = """
        You prepare an expense for a budgeting app from an Apple Pay payment. \
        You receive the transaction name exactly as Apple Wallet reports it. \
        Return a budget category.

        Category: needs (rent, groceries, bills, health, essential transport), \
        wants (dining out, coffee, entertainment, shopping, subscriptions), \
        savingsAndDebts (savings, investments, debt repayments, retirement). \
        If the transaction is unclear or could fit several categories, leave the category empty.

        Transactions are mostly in Spain or France. Names can be Spanish, French or English.
        """

    static func prompt(for transaction: String) -> String {
        """
        Transaction: \(transaction)
        """
    }
}
