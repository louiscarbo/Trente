//
//  MonthDeletionTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 31/10/2026.
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@MainActor
@Suite(.serialized)
struct MonthDeletionTests {
    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func insertExpense(titled title: String, in month: Month, context: ModelContext) {
        let group = TransactionGroup(title: title, type: .expense, month: month, note: nil, imageAttachmentData: nil)
        context.insert(group)
        group.entries = [TransactionEntry(amountCents: -10_00, category: .needs, group: group)]
        month.transactionGroups.append(group)
    }

    @Test("Leaving the latest month moves to the month before it")
    func leavesLatestMonth() throws {
        let context = try makeContext()
        let september = insertMonth(year: 2026, month: 9, in: context)
        let october = insertMonth(year: 2026, month: 10, in: context)

        let selection = SidebarSelection.month(october).leaving([october], for: september)

        #expect(selection == .month(september))
    }

    @Test("Leaving an older month moves to the latest month")
    func leavesOlderMonth() throws {
        let context = try makeContext()
        let september = insertMonth(year: 2026, month: 9, in: context)
        let october = insertMonth(year: 2026, month: 10, in: context)

        let selection = SidebarSelection.month(september).leaving([september], for: october)

        #expect(selection == .month(october))
    }

    @Test("Leaving the only month selects nothing, so the dashboard closes before the delete")
    func leavesOnlyMonth() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)

        let selection = SidebarSelection.month(october).leaving([october], for: nil)

        #expect(selection == nil)
    }

    @Test("Leaving a month that isn't on screen keeps the selection")
    func keepsOtherSelection() throws {
        let context = try makeContext()
        let september = insertMonth(year: 2026, month: 9, in: context)
        let october = insertMonth(year: 2026, month: 10, in: context)

        #expect(SidebarSelection.month(october).leaving([september], for: october) == .month(october))
        #expect(SidebarSelection.recurring.leaving([september], for: october) == .recurring)
    }

    @Test("Deleting a month saves the removal of its transactions and spares the others")
    func deletesMonthAndItsTransactions() throws {
        let context = try makeContext()
        let september = insertMonth(year: 2026, month: 9, in: context)
        let october = insertMonth(year: 2026, month: 10, in: context)
        insertExpense(titled: "Rent", in: september, context: context)
        insertExpense(titled: "Groceries", in: october, context: context)
        try context.save()
        var errors: [String] = []

        TransactionActions { errors.append($0) }.delete(october, in: context)

        #expect(errors.isEmpty)
        #expect(!context.hasChanges)
        #expect(try context.fetch(FetchDescriptor<Month>()).map(\.id) == [september.id])
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).map(\.title) == ["Rent"])
        #expect(try context.fetch(FetchDescriptor<TransactionEntry>()).count == 1)
    }

    @Test("Catching up after deleting the latest month brings it back empty")
    func recreatesLatestMonth() throws {
        let context = try makeContext()
        let september = insertMonth(year: 2026, month: 9, in: context)
        september.idealBudgetCents = 3100_00
        let october = insertMonth(year: 2026, month: 10, in: context)
        insertExpense(titled: "Groceries", in: october, context: context)
        try context.save()
        let deletedID = october.id

        TransactionActions { _ in }.delete(october, in: context)
        try CatchUpService.shared.catchUp(in: context, now: day(2026, 10, 20), isTrentePlusSubscribed: false)

        let months = try context.fetch(FetchDescriptor<Month>(sortBy: [SortDescriptor(\.startDate)]))
        #expect(months.map(\.startDate) == [day(2026, 9, 1), day(2026, 10, 1)])
        let recreated = try #require(months.last)
        #expect(recreated.id != deletedID)
        #expect(recreated.transactionGroups.isEmpty)
        #expect(recreated.idealBudgetCents == 3100_00)
    }
}
