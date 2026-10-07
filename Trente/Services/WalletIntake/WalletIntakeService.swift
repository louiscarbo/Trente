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
    func intake(
        transaction: String,
        amount: String,
        in context: ModelContext,
        now: Date = .now
    ) throws -> PendingTransaction {
        guard let cents = WalletAmountParser.cents(from: amount) else {
            throw WalletIntakeError.unreadableAmount
        }
        let title = transaction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw WalletIntakeError.missingTitle
        }

        let pending = PendingTransaction(
            date: now,
            amountCents: -cents,
            title: title
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
        guard let month = try MonthService.shared.latestMonth(in: context) else {
            throw WalletIntakeError.noMonth
        }
        let pending = try intake(
            transaction: transaction,
            amount: amount,
            in: context
        )
        do {
            try await WalletNotificationService.shared.post(for: pending, currency: month.currency)
        } catch {
            try? PendingTransactionService.shared.discard(pending, in: context)
            throw error
        }
    }
}
