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

final class PendingTransactionService {
    static let shared = PendingTransactionService()
    private init() {}

    func validate(_ pending: PendingTransaction, with draft: TransactionGroupDraft, in context: ModelContext) throws {
        guard let month = try MonthService.shared.latestMonth(in: context) else {
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

        try TransactionService.shared.create(with: request, for: month, in: context)
        context.delete(pending)
        try context.save()
    }

    func discard(_ pending: PendingTransaction, in context: ModelContext) throws {
        context.delete(pending)
        try context.save()
    }
}
