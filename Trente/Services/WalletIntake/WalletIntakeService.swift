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

enum WalletIntakeResult {
    case logged(PendingTransaction)
    case limitReached
}

@MainActor
struct WalletIntakeService {
    var allowance = WalletIntakeAllowance()

    func intake(
        transaction: String,
        amount: String,
        in context: ModelContext,
        now: Date = .now,
        isTrentePlusSubscribed: Bool
    ) throws -> WalletIntakeResult {
        guard let cents = WalletAmountParser.cents(from: amount) else {
            throw WalletIntakeError.unreadableAmount
        }
        let title = transaction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw WalletIntakeError.missingTitle
        }
        guard allowance.allowsIntake(on: now, isTrentePlusSubscribed: isTrentePlusSubscribed) else {
            return .limitReached
        }

        let pending = PendingTransaction(
            date: now,
            amountCents: -cents,
            title: title
        )
        context.insert(pending)
        try context.save()
        allowance.recordIntake(on: now)
        return .logged(pending)
    }

    func currentMonth(in context: ModelContext, now: Date = .now) throws -> Month {
        try CatchUpService.shared.catchUp(in: context, now: now)
        guard let month = try MonthService.shared.latestMonth(in: context) else {
            throw WalletIntakeError.noMonth
        }
        return month
    }

    func handle(
        transaction: String,
        amount: String,
        in context: ModelContext,
        now: Date = .now,
        isTrentePlusSubscribed: Bool = TrentePlusEntitlement.cached()
    ) async throws {
        let month = try currentMonth(in: context, now: now)
        let result = try intake(
            transaction: transaction,
            amount: amount,
            in: context,
            now: now,
            isTrentePlusSubscribed: isTrentePlusSubscribed
        )
        switch result {
        case .logged(let pending):
            try? await WalletNotificationService.shared.post(for: pending, currency: month.currency)
        case .limitReached:
            guard !allowance.hasSentLimitNotice(on: now) else { return }
            guard (try? await WalletNotificationService.shared.postLimitReached()) != nil else { return }
            allowance.recordLimitNotice(on: now)
        }
    }
}
