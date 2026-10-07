//
//  WalletSuggestionPrompt.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

enum WalletSuggestionPrompt {
    static let instructions = """
        You prepare an expense for a budgeting app from an Apple Pay payment. \
        You receive the merchant and the transaction name exactly as Apple Wallet reports them. \
        Return a budget category.

        Category: needs (rent, groceries, bills, health, essential transport), \
        wants (dining out, coffee, entertainment, shopping, subscriptions), \
        savingsAndDebts (savings, investments, debt repayments, retirement). \
        If the merchant is unclear or could fit several categories, leave the category empty.

        Merchants are mostly in Spain or France. Names can be Spanish, French or English.
        """

    static func prompt(for transaction: WalletTransaction) -> String {
        """
        Merchant: \(transaction.merchant)
        Name: \(transaction.name)
        """
    }
}
