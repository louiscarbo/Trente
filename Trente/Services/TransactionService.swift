//
//  TransactionService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 21/04/2025.
//

import Foundation
import SwiftData

enum TransactionServiceError: Error {
    case missingCategoryForExpense
    case invalidRepartition
}

final class TransactionService {
    static let shared = TransactionService()
    private init() {}

    // TODO: Check if it really works :/
    func fetchTransactionDateBounds(from model: ModelContext) throws -> ClosedRange<Date> {
        let defaultEarliest = Date.distantPast
        let defaultLatest   = Date.distantFuture

        let descriptor = FetchDescriptor<TransactionGroup>(
            sortBy: [ SortDescriptor(\.addedDate, order: .forward) ]
        )

        let groups = try model.fetch(descriptor)
        let earliest = groups.first?.addedDate ?? defaultEarliest
        let latest   = groups.last?.addedDate  ?? defaultLatest

        return earliest...latest
    }
    
    func create(with request: TransactionCreationRequest, for month: Month, in context: ModelContext) throws {
        if request.isRecurrent {
            let rule = RecurringTransactionRule(
                title: request.title,
                frequency: request.recurrenceFrequency,
                startDate: request.recurrenceStartDate,
                endDate: request.recurrenceEndDate,
                repartition: request.repartition
            )
            context.insert(rule)
            
            if Calendar.current.isDateInToday(request.recurrenceStartDate) {
                try createTransactionGroupWithEntries(from: request, for: month, in: context)
            }
            
            try RecurringTransactionService.shared.refreshInstances(for: month, in: context)
            
        } else {
            try createTransactionGroupWithEntries(from: request, for: month, in: context)
        }
        
        try context.save()
    }
}

private extension TransactionService {
    func createTransactionGroupWithEntries(from request: TransactionCreationRequest, for month: Month, in context: ModelContext) throws {
        // Transaction validation
        if request.type == .expense {
            guard request.selectedCategory != nil else {
                throw TransactionServiceError.missingCategoryForExpense
            }
        }
        if request.type == .income {
            guard request.repartition.values.contains(where: { $0 > 0 }) else {
                throw TransactionServiceError.invalidRepartition
            }
        }
        
        let group = TransactionGroup(
            title: request.title,
            type: request.type,
            month: month,
            note: request.notes,
            imageAttachmentData: request.imageData
        )
        context.insert(group)
        
        if request.type == .expense, let category = request.selectedCategory {
            let entry = TransactionEntry(
                amountCents: request.amountCents,
                category: category,
                group: group
            )
            context.insert(entry)
        } else if request.type == .income {
            for (category, amount) in request.repartition where amount > 0 {
                let entry = TransactionEntry(
                    amountCents: amount,
                    category: category,
                    group: group
                )
                context.insert(entry)
            }
        }
    }
}
