//
//  TransactionService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 21/04/2025.
//

import Foundation
import SwiftData

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
    
    func fetchTransactionsCount(from model: ModelContext) -> Int {
        let descriptor = FetchDescriptor<TransactionGroup>()
        do {
            let groupsCount = try model.fetchCount(descriptor)
            return groupsCount
        } catch {
            print("⚠️ fetchTransactionsCount failed:", error)
            return 0
        }
    }
}
