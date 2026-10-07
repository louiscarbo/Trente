//
//  MonthService.swift
//  Trente
//
//  Created by Jules on 02/08/2025.
//

import Foundation
import SwiftData

final class MonthService {
    static let shared = MonthService()
    private init() {}

    func create(month: Month, in context: ModelContext) throws {
        context.insert(month)
        try RecurringTransactionService.shared.refreshInstances(for: month, in: context)
        try context.save()
    }

    func latestMonth(in context: ModelContext) throws -> Month? {
        var descriptor = FetchDescriptor<Month>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
