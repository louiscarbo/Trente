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
        try context.save()
    }

    func latestMonth(in context: ModelContext) throws -> Month? {
        var descriptor = FetchDescriptor<Month>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func createMissingMonths(
        in context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> [Month] {
        guard let latestMonth = try latestMonth(in: context) else { return [] }
        let missingStartDates = startDatesOfMissingMonths(
            after: latestMonth.startDate,
            today: now,
            calendar: calendar
        )
        guard !missingStartDates.isEmpty else { return [] }

        let createdMonths = missingStartDates.map { startDate in
            Month(
                startDate: startDate,
                currency: latestMonth.currency,
                idealBudgetCents: latestMonth.idealBudgetCents,
                idealRepartition: latestMonth.idealRepartition
            )
        }
        createdMonths.forEach { context.insert($0) }
        try context.save()
        return createdMonths
    }

    func startDatesOfMissingMonths(
        after latestStartDate: Date?,
        today: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard let latestStartDate else { return [] }
        var missingStartDates: [Date] = []
        var previousStartDate = calendar.startOfDay(for: latestStartDate)
        while let nextStartDate = calendar.date(byAdding: .month, value: 1, to: previousStartDate),
              nextStartDate <= today {
            missingStartDates.append(nextStartDate)
            previousStartDate = nextStartDate
        }
        return missingStartDates
    }
}
