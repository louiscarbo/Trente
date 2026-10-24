//
//  SyncDuplicateCleanerTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Trente

@Suite(.serialized)
struct SyncDuplicateCleanerTests {
    @discardableResult
    private func insertGroup(
        _ title: String,
        in month: Month,
        rule: RecurringTransactionRule? = nil,
        occurrenceDate: Date? = nil,
        context: ModelContext
    ) -> TransactionGroup {
        let group = TransactionGroup(title: title, type: .expense, month: month, note: nil, imageAttachmentData: nil)
        context.insert(group)
        group.entries = [TransactionEntry(amountCents: -10_00, category: .needs, group: group)]
        group.recurringRule = rule
        group.recurringOccurrenceDate = occurrenceDate
        month.transactionGroups.append(group)
        return group
    }

    private func insertRule(startingOn startDate: Date, in context: ModelContext) -> RecurringTransactionRule {
        let rule = RecurringTransactionRule(
            title: "Salary",
            frequency: .monthly,
            startDate: startDate,
            autoConfirm: true,
            repartition: [.needs: 1000_00]
        )
        context.insert(rule)
        return rule
    }

    @Test("Two months starting the same day become one, keeping every transaction")
    func mergesDuplicateMonths() throws {
        let context = try makeContext()
        let first = insertMonth(year: 2026, month: 11, in: context)
        let second = insertMonth(year: 2026, month: 11, in: context)
        insertGroup("Bread", in: first, context: context)
        insertGroup("Rent", in: second, context: context)
        try context.save()

        let changed = try SyncDuplicateCleaner.mergeDuplicates(in: context)

        let months = try context.fetch(FetchDescriptor<Month>())
        #expect(changed)
        #expect(months.count == 1)
        #expect(Set(months.first?.transactionGroups.map(\.title) ?? []) == ["Bread", "Rent"])
    }

    @Test("Every device keeps the same month: the one with the smallest id")
    func keeperIsDeterministic() throws {
        let context = try makeContext()
        let first = insertMonth(year: 2026, month: 11, in: context)
        let second = insertMonth(year: 2026, month: 11, in: context)
        let expected = first.id.uuidString < second.id.uuidString ? first.id : second.id
        try context.save()

        try SyncDuplicateCleaner.mergeDuplicates(in: context)

        #expect(try context.fetch(FetchDescriptor<Month>()).map(\.id) == [expected])
    }

    @Test("An automatic recurring transaction recorded on two devices is kept once")
    func removesDuplicateRecurringTransactions() throws {
        let context = try makeContext()
        let november = insertMonth(year: 2026, month: 11, in: context)
        let payday = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 5)))
        let rule = insertRule(startingOn: payday, in: context)
        insertGroup("Salary", in: november, rule: rule, occurrenceDate: payday, context: context)
        insertGroup("Salary", in: november, rule: rule, occurrenceDate: payday.addingTimeInterval(3600), context: context)
        try context.save()

        try SyncDuplicateCleaner.mergeDuplicates(in: context)

        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<TransactionEntry>()).count == 1)
    }

    @Test("Different months and different occurrences are left alone")
    func leavesDistinctDataAlone() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        let november = insertMonth(year: 2026, month: 11, in: context)
        let october5 = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 5)))
        let november5 = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 5)))
        let rule = insertRule(startingOn: october5, in: context)
        insertGroup("Salary", in: october, rule: rule, occurrenceDate: october5, context: context)
        insertGroup("Salary", in: november, rule: rule, occurrenceDate: november5, context: context)
        insertGroup("Bread", in: november, context: context)
        insertGroup("Bread", in: november, context: context)
        try context.save()

        let changed = try SyncDuplicateCleaner.mergeDuplicates(in: context)

        #expect(!changed)
        #expect(try context.fetch(FetchDescriptor<Month>()).count == 2)
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).count == 4)
    }
}
