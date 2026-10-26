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

    @Test("Between two unedited months, every device keeps the one with the smallest id")
    func keeperIsDeterministic() throws {
        let context = try makeContext()
        let first = insertMonth(year: 2026, month: 11, in: context)
        let second = insertMonth(year: 2026, month: 11, in: context)
        let expected = first.id.uuidString < second.id.uuidString ? first.id : second.id
        try context.save()

        try SyncDuplicateCleaner.mergeDuplicates(in: context)

        #expect(try context.fetch(FetchDescriptor<Month>()).map(\.id) == [expected])
    }

    @Test("The month edited most recently wins over the smallest id")
    func keepsEditedMonth() throws {
        let context = try makeContext()
        let first = insertMonth(year: 2026, month: 11, in: context)
        let second = insertMonth(year: 2026, month: 11, in: context)
        let edited = first.id.uuidString < second.id.uuidString ? second : first
        edited.idealBudgetCents = 3000_00
        edited.modifiedDate = .now
        try context.save()

        try SyncDuplicateCleaner.mergeDuplicates(in: context)

        let months = try context.fetch(FetchDescriptor<Month>())
        #expect(months.map(\.id) == [edited.id])
        #expect(months.first?.idealBudgetCents == 3000_00)
    }

    @Test("Three copies of a month become one")
    func mergesThreeMonths() throws {
        let context = try makeContext()
        for title in ["Bread", "Rent", "Gym"] {
            insertGroup(title, in: insertMonth(year: 2026, month: 11, in: context), context: context)
        }
        try context.save()

        try SyncDuplicateCleaner.mergeDuplicates(in: context)

        let months = try context.fetch(FetchDescriptor<Month>())
        #expect(months.count == 1)
        #expect(months.first?.transactionGroups.count == 3)
    }

    @Test("A second run finds nothing to do")
    func secondRunIsNoOp() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 11, in: context)
        insertMonth(year: 2026, month: 11, in: context)
        try context.save()

        #expect(try SyncDuplicateCleaner.mergeDuplicates(in: context))
        #expect(try !SyncDuplicateCleaner.mergeDuplicates(in: context))
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

    @Test("A recurring transaction edited on one device survives over the automatic copy")
    func keepsEditedRecurringTransaction() throws {
        let context = try makeContext()
        let november = insertMonth(year: 2026, month: 11, in: context)
        let payday = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 5)))
        let rule = insertRule(startingOn: payday, in: context)
        let first = insertGroup("Salary", in: november, rule: rule, occurrenceDate: payday, context: context)
        let second = insertGroup("Salary", in: november, rule: rule, occurrenceDate: payday, context: context)
        let edited = first.id.uuidString < second.id.uuidString ? second : first
        edited.note = "Bonus included"
        edited.modifiedDate = .now.addingTimeInterval(60)
        try context.save()

        try SyncDuplicateCleaner.mergeDuplicates(in: context)

        let groups = try context.fetch(FetchDescriptor<TransactionGroup>())
        #expect(groups.map(\.id) == [edited.id])
        #expect(groups.first?.note == "Bonus included")
    }

    @Test("Recurring copies sitting in two duplicate months end up as one transaction in one month")
    func mergesRecurringAcrossDuplicateMonths() throws {
        let context = try makeContext()
        let first = insertMonth(year: 2026, month: 11, in: context)
        let second = insertMonth(year: 2026, month: 11, in: context)
        let payday = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 5)))
        let rule = insertRule(startingOn: payday, in: context)
        insertGroup("Salary", in: first, rule: rule, occurrenceDate: payday, context: context)
        insertGroup("Salary", in: second, rule: rule, occurrenceDate: payday, context: context)
        try context.save()

        try SyncDuplicateCleaner.mergeDuplicates(in: context)

        let months = try context.fetch(FetchDescriptor<Month>())
        #expect(months.count == 1)
        #expect(months.first?.transactionGroups.count == 1)
    }

    @Test("A transaction left without a month goes back to the month containing its date")
    func reattachesOrphans() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        let november = insertMonth(year: 2026, month: 11, in: context)
        let orphan = insertGroup("Bread", in: october, context: context)
        orphan.addedDate = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 12)))
        orphan.month = nil
        try context.save()

        #expect(try SyncDuplicateCleaner.mergeDuplicates(in: context))

        #expect(orphan.month?.id == november.id)
    }

    @Test("A recurring orphan uses its occurrence date, not the day it was confirmed")
    func reattachesRecurringOrphanByOccurrence() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        insertMonth(year: 2026, month: 11, in: context)
        let october30 = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 30)))
        let rule = insertRule(startingOn: october30, in: context)
        let orphan = insertGroup("Salary", in: october, rule: rule, occurrenceDate: october30, context: context)
        orphan.addedDate = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 2)))
        orphan.month = nil
        try context.save()

        try SyncDuplicateCleaner.mergeDuplicates(in: context)

        #expect(orphan.month?.id == october.id)
    }

    @Test("An orphan with no month covering its date is left alone")
    func leavesUnplaceableOrphanAlone() throws {
        let context = try makeContext()
        let november = insertMonth(year: 2026, month: 11, in: context)
        let orphan = insertGroup("Bread", in: november, context: context)
        orphan.addedDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 3)))
        orphan.month = nil
        try context.save()

        #expect(try !SyncDuplicateCleaner.mergeDuplicates(in: context))
        #expect(orphan.month == nil)
    }

    @Test("Deleting a duplicate month never deletes its transactions")
    func monthDeletionDoesNotCascade() throws {
        let context = try makeContext()
        let november = insertMonth(year: 2026, month: 11, in: context)
        insertGroup("Bread", in: november, context: context)
        try context.save()

        context.delete(november)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).count == 1)
    }

    @Test("Deleting a month from the app deletes its transactions and their entries")
    func monthServiceDeletesTransactions() throws {
        let context = try makeContext()
        let november = insertMonth(year: 2026, month: 11, in: context)
        insertGroup("Bread", in: november, context: context)
        try context.save()

        MonthService.shared.delete(month: november, in: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Month>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<TransactionEntry>()).isEmpty)
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
