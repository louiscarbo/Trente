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
    case recurrenceStartsInPast
}

final class TransactionService: Sendable {
    static let shared = TransactionService()
    private init() {}

    func fetchTransactionDateBounds(from model: ModelContext) throws -> ClosedRange<Date> {
        var earliestDescriptor = FetchDescriptor<TransactionGroup>(sortBy: [SortDescriptor(\.addedDate)])
        earliestDescriptor.fetchLimit = 1
        var latestDescriptor = FetchDescriptor<TransactionGroup>(sortBy: [SortDescriptor(\.addedDate, order: .reverse)])
        latestDescriptor.fetchLimit = 1

        let earliest = try model.fetch(earliestDescriptor).first?.addedDate ?? .distantPast
        let latest = try model.fetch(latestDescriptor).first?.addedDate ?? .distantFuture
        return earliest...latest
    }
    
    func delete(group: TransactionGroup, in context: ModelContext) {
        context.delete(group)
    }

    @MainActor
    func create(with request: TransactionCreationRequest, for month: Month, in context: ModelContext) throws {
        try insert(with: request, for: month, in: context)
        try context.save()
    }

    @MainActor
    func insert(with request: TransactionCreationRequest, for month: Month, in context: ModelContext) throws {
        if request.isRecurrent {
            guard request.recurrenceStartDate >= Calendar.current.startOfDay(for: .now) else {
                throw TransactionServiceError.recurrenceStartsInPast
            }
            let rule = RecurringTransactionRule(
                title: request.title,
                frequency: request.recurrenceFrequency,
                startDate: request.recurrenceStartDate,
                endDate: request.recurrenceEndDate,
                repartition: try recurringRepartition(from: request)
            )
            context.insert(rule)
        } else {
            try createTransactionGroupWithEntries(from: request, for: month, in: context)
        }
    }
}

@MainActor
private extension TransactionService {
    func recurringRepartition(from request: TransactionCreationRequest) throws -> [BudgetCategory: Int] {
        switch request.type {
        case .expense:
            guard let category = request.selectedCategory else {
                throw TransactionServiceError.missingCategoryForExpense
            }
            return [category: request.amountCents]
        case .income:
            let repartition = request.repartition.filter { $0.value > 0 }
            guard !repartition.isEmpty else {
                throw TransactionServiceError.invalidRepartition
            }
            return repartition
        }
    }

    @discardableResult
    func createTransactionGroupWithEntries(from request: TransactionCreationRequest, for month: Month, in context: ModelContext) throws -> TransactionGroup {
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
            imageAttachmentData: request.imageData,
            addedDate: request.date
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
        return group
    }
}
