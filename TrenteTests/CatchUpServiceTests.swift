//
//  CatchUpServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@MainActor
@Suite(.serialized)
struct CatchUpServiceTests {
    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test("Catching up starts the missing months before confirming their automatic transactions")
    func catchUpCreatesMonthsThenConfirms() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 8, in: context)
        context.insert(RecurringTransactionRule(
            title: "Rent",
            frequency: .monthly,
            startDate: day(2026, 8, 2),
            autoConfirm: true,
            repartition: [.needs: -800_00],
            createdAt: day(2026, 8, 2)
        ))
        try context.save()

        try CatchUpService.shared.catchUp(in: context, now: day(2026, 10, 10))

        let months = try context.fetch(FetchDescriptor<Month>(sortBy: [SortDescriptor(\.startDate)]))
        #expect(months.map(\.startDate) == [day(2026, 8, 1), day(2026, 9, 1), day(2026, 10, 1)])
        #expect(months.map(\.transactionGroups.count) == [1, 1, 1])
    }
}
