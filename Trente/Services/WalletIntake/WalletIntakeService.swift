//
//  WalletIntakeService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Foundation
import SwiftData

enum WalletIntakeError: Error {
    case unreadableAmount
    case noMonth
    case missingTitle
}

@MainActor
struct WalletIntakeService {
    var suggester: any TransactionSuggesting = TransactionSuggester()
    var suggestionTimeout: Duration = .seconds(5)

    func intake(
        transaction: String,
        amount: String,
        in context: ModelContext,
        now: Date = .now
    ) async throws -> PendingTransaction {
        guard let cents = WalletAmountParser.cents(from: amount) else {
            throw WalletIntakeError.unreadableAmount
        }
        guard try MonthService.shared.latestMonth(in: context) != nil else {
            throw WalletIntakeError.noMonth
        }
        let title = transaction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw WalletIntakeError.missingTitle
        }

        let pending = PendingTransaction(
            date: now,
            amountCents: -cents,
            title: title,
            category: await suggestedCategory(for: title)
        )
        context.insert(pending)
        try context.save()
        return pending
    }

    func handle(
        transaction: String,
        amount: String,
        in context: ModelContext
    ) async throws {
        let pending = try await intake(
            transaction: transaction,
            amount: amount,
            in: context
        )
        guard let currency = try MonthService.shared.latestMonth(in: context)?.currency else {
            throw WalletIntakeError.noMonth
        }
        try await WalletNotificationService.shared.post(for: pending, currency: currency)
    }

    private func suggestedCategory(for transaction: String) async -> BudgetCategory? {
        let suggester = suggester
        let timeout = suggestionTimeout
        return await withTaskGroup(of: BudgetCategory?.self) { group in
            group.addTask {
                try? await suggester.suggestCategory(for: transaction)
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
