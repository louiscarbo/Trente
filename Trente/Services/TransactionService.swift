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

    func fetchTransactionDateBounds(from model: ModelContext) -> ClosedRange<Date> {
        let defaultEarliest = Date.distantPast
        let defaultLatest   = Date.distantFuture

        let descriptor = FetchDescriptor<TransactionGroup>(
            sortBy: [ SortDescriptor(\.addedDate, order: .forward) ]
        )

        do {
            let groups = try model.fetch(descriptor)
            let earliest = groups.first?.addedDate ?? defaultEarliest
            let latest   = groups.last?.addedDate  ?? defaultLatest

            return earliest...latest

        } catch {
            print("⚠️ fetchTransactionDateBounds failed:", error)
            return defaultEarliest...defaultLatest
        }
    }
}
