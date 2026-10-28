//
//  PendingTransactionService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Foundation
import SwiftData

enum PendingTransactionError: Error {
    case noMonth
}

final class PendingTransactionService: Sendable {
    static let shared = PendingTransactionService()
    private init() {}

    func validate(_ pending: PendingTransaction, with draft: TransactionGroupDraft, in context: ModelContext) throws {
        let purchaseMonth = try MonthService.shared.month(containing: pending.date, in: context)
        guard let month = try purchaseMonth ?? MonthService.shared.latestMonth(in: context) else {
            throw PendingTransactionError.noMonth
        }

        let request = TransactionCreationRequest()
        request.title = draft.title
        request.amountCents = draft.expenseAmountCents ?? pending.amountCents
        request.type = .expense
        request.selectedCategory = draft.expenseCategory
        request.notes = draft.note ?? ""
        request.imageData = draft.imageAttachmentData
        request.date = pending.date

        do {
            try TransactionService.shared.insert(with: request, for: month, in: context)
            context.delete(pending)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func discard(_ pending: PendingTransaction, in context: ModelContext) throws {
        context.delete(pending)
        try context.save()
    }
}
