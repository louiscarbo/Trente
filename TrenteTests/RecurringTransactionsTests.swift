//
//  RecurringTransactionsTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import Testing
import SwiftData
@testable import Trente
import Foundation
import Synchronization

@Suite(.serialized)
struct RecurringTransactionsTests {
    private let calendar = Calendar.current
    private let service = RecurringTransactionService.shared

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @discardableResult
    private func insertRule(
        _ title: String,
        startingOn startDate: Date,
        repartition: [BudgetCategory: Int],
        automatic: Bool = false,
        in context: ModelContext
    ) -> RecurringTransactionRule {
        let rule = RecurringTransactionRule(
            title: title,
            frequency: .monthly,
            startDate: startDate,
            autoConfirm: automatic,
            repartition: repartition,
            createdAt: startDate
        )
        context.insert(rule)
        return rule
    }

    @Test("A month's pending occurrences come from the rule's schedule")
    func pendingOccurrencesFollowSchedule() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), repartition: [.needs: -800_00], in: context)
        try context.save()

        let occurrences = service.pendingOccurrences(of: [rule], in: april)

        #expect(occurrences.map(\.date) == [day(2025, 4, 15)])
        #expect(occurrences.first?.amountCents == -800_00)
    }

    @Test("Confirming an income occurrence creates a linked income transaction")
    func confirmIncome() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Salary", startingOn: day(2025, 4, 1), repartition: [.needs: 1500_00, .wants: 500_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)

        try service.confirm(occurrence, in: context)

        let group = try #require(april.transactionGroups.first)
        #expect(april.transactionGroups.count == 1)
        #expect(group.type == .income)
        #expect(group.entries.count == 2)
        #expect(group.totalAmountCents == 2000_00)
        #expect(group.recurringRule?.persistentModelID == rule.persistentModelID)
        #expect(group.recurringOccurrenceDate == day(2025, 4, 1))
        #expect(service.pendingOccurrences(of: [rule], in: april).isEmpty)
    }

    @Test("Confirming an expense occurrence creates an expense transaction")
    func confirmExpense() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)

        try service.confirm(occurrence, in: context)

        let group = try #require(april.transactionGroups.first)
        #expect(group.type == .expense)
        #expect(group.entries.map(\.amountCents) == [-800_00])
        #expect(group.entries.first?.category == .needs)
    }

    @Test("Confirming the same occurrence twice creates a single transaction")
    func confirmTwice() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Salary", startingOn: day(2025, 4, 1), repartition: [.needs: 1000_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)

        try service.confirm(occurrence, in: context)
        try service.confirm(occurrence, in: context)

        #expect(april.transactionGroups.count == 1)
    }

    @Test("Deleting a confirmed transaction makes its occurrence pending again")
    func deletingConfirmedTransactionRestoresOccurrence() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)
        try service.confirm(occurrence, in: context)
        let group = try #require(april.transactionGroups.first)

        TransactionService.shared.delete(group: group, in: context)
        try context.save()

        #expect(service.pendingOccurrences(of: [rule], in: april).map(\.date) == [day(2025, 4, 2)])
    }

    @Test("Deleting a rule keeps the transactions it created")
    func deletingRuleKeepsTransactions() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)
        try service.confirm(occurrence, in: context)

        service.delete(rule: rule, in: context)
        try context.save()

        let groups = try context.fetch(FetchDescriptor<TransactionGroup>())
        #expect(groups.count == 1)
        #expect(groups.first?.recurringRule == nil)
        #expect(try context.fetch(FetchDescriptor<RecurringTransactionRule>()).isEmpty)
    }

    @Test("Moving the payment day doesn't bring back an occurrence already confirmed that month")
    func movingPaymentDayKeepsMonthSettled() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)
        try service.confirm(occurrence, in: context)

        rule.startDate = day(2025, 4, 20)
        try context.save()

        #expect(service.pendingOccurrences(of: [rule], in: april).isEmpty)
    }

    @Test("Confirming one month leaves the next month's occurrence pending")
    func confirmingOneMonthLeavesOthersPending() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let may = insertMonth(year: 2025, month: 5, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)

        try service.confirm(occurrence, in: context)

        #expect(service.pendingOccurrences(of: [rule], in: may).map(\.date) == [day(2025, 5, 2)])
    }

    @Test("Pending occurrences of several rules are sorted by date")
    func pendingOccurrencesAreSorted() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let netflix = insertRule("Netflix", startingOn: day(2025, 1, 22), repartition: [.wants: -13_99], in: context)
        let rent = insertRule("Rent", startingOn: day(2025, 1, 2), repartition: [.needs: -800_00], in: context)
        try context.save()

        let titles = service.pendingOccurrences(of: [netflix, rent], in: april).map(\.rule.title)

        #expect(titles == ["Rent", "Netflix"])
    }

    @Test("Skipping an occurrence hides it in its month only")
    func skippingHidesOnlyThatMonth() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let may = insertMonth(year: 2025, month: 5, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)

        try service.skip(occurrence, in: context)

        #expect(service.pendingOccurrences(of: [rule], in: april).isEmpty)
        #expect(service.pendingOccurrences(of: [rule], in: may).map(\.date) == [day(2025, 5, 2)])
        #expect(april.transactionGroups.isEmpty)
    }

    @Test("Skipping the same occurrence twice stores it once")
    func skippingTwiceStoresOnce() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)

        try service.skip(occurrence, in: context)
        try service.skip(occurrence, in: context)

        #expect(rule.skippedOccurrenceDates.count == 1)
    }

    @Test("Stopping a rule keeps today's payment and drops the following ones")
    func stoppingKeepsTodayAndDropsFuture() throws {
        let context = try makeContext()
        let today = calendar.startOfDay(for: .now)
        let thisMonthComponents = calendar.dateComponents([.year, .month], from: today)
        let thisMonth = insertMonth(year: thisMonthComponents.year!, month: thisMonthComponents.month!, in: context)
        let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: thisMonth.startDate)!
        let nextMonthComponents = calendar.dateComponents([.year, .month], from: nextMonthStart)
        let nextMonth = insertMonth(year: nextMonthComponents.year!, month: nextMonthComponents.month!, in: context)
        let rule = insertRule("Gym", startingOn: today, repartition: [.wants: -29_00], in: context)
        try context.save()
        #expect(!rule.hasEnded)

        try service.stop(rule, in: context)

        #expect(rule.hasEnded)
        #expect(service.pendingOccurrences(of: [rule], in: thisMonth).map(\.date) == [today])
        #expect(service.pendingOccurrences(of: [rule], in: nextMonth).isEmpty)
    }

    @Test("Confirming by hand dates the transaction now")
    func manualConfirmIsDatedNow() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrence = try #require(service.pendingOccurrences(of: [rule], in: april).first)

        try service.confirm(occurrence, in: context)

        let group = try #require(april.transactionGroups.first)
        #expect(abs(group.addedDate.timeIntervalSinceNow) < 60)
    }

    @Test("Catching up confirms due automatic transactions on their due date")
    func catchUpConfirmsOnDueDate() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], automatic: true, in: context)
        try context.save()

        let confirmedCount = try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: true)

        #expect(confirmedCount == 1)
        let group = try #require(april.transactionGroups.first)
        #expect(group.addedDate == day(2025, 4, 2))
        #expect(group.recurringOccurrenceDate == day(2025, 4, 2))
    }

    @Test("Catching up leaves manual, future and skipped transactions alone")
    func catchUpSkipsManualFutureAndSkipped() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let netflix = insertRule("Netflix", startingOn: day(2025, 4, 5), repartition: [.wants: -13_99], in: context)
        let gym = insertRule("Gym", startingOn: day(2025, 4, 28), repartition: [.wants: -29_00], automatic: true, in: context)
        let rent = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], automatic: true, in: context)
        try context.save()
        try service.skip(try #require(rent.pendingOccurrences(in: april).first), in: context)

        let confirmedCount = try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: true)

        #expect(confirmedCount == 0)
        #expect(april.transactionGroups.isEmpty)
        #expect(service.pendingOccurrences(of: [netflix, gym, rent], in: april).map(\.rule.title) == ["Netflix", "Gym"])
    }

    @Test("Catching up twice confirms once")
    func catchUpTwiceConfirmsOnce() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], automatic: true, in: context)
        try context.save()

        try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: true)
        let secondCount = try service.confirmDueOccurrences(in: context, now: day(2025, 4, 11), isAutomaticUnlocked: true)

        #expect(secondCount == 0)
        #expect(april.transactionGroups.count == 1)
    }

    @Test("A deleted automatic transaction comes back as pending instead of being recorded again")
    func deletedAutomaticTransactionStaysPending() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], automatic: true, in: context)
        try context.save()
        try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: true)
        let group = try #require(april.transactionGroups.first)

        TransactionService.shared.delete(group: group, in: context)
        try context.save()
        let secondCount = try service.confirmDueOccurrences(in: context, now: day(2025, 4, 11), isAutomaticUnlocked: true)

        #expect(secondCount == 0)
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).isEmpty)
        #expect(service.pendingOccurrences(of: [rule], in: april).map(\.date) == [day(2025, 4, 2)])
    }

    @Test("A month's figures can include automatic transactions not recorded yet")
    func figuresIncludeAutomaticOccurrences() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let salary = insertRule("Salary", startingOn: day(2025, 4, 1), repartition: [.needs: 1000_00, .wants: 500_00], in: context)
        let rent = insertRule("Rent", startingOn: day(2025, 4, 2), repartition: [.needs: -800_00], in: context)
        try context.save()
        let occurrences = service.pendingOccurrences(of: [salary, rent], in: april)

        let overall = april.figures(in: .all, including: occurrences)
        let needs = april.figures(in: .category(.needs), including: occurrences)
        let wants = april.figures(in: .category(.wants), including: occurrences)

        #expect(overall == BudgetFigures(spent: 800, income: 1500, remaining: 700))
        #expect(needs == BudgetFigures(spent: 800, income: 1000, remaining: 200))
        #expect(wants == BudgetFigures(spent: 0, income: 500, remaining: 500))
    }

    private func countSaves(of context: ModelContext, during work: () throws -> Void) rethrows -> Int {
        let saveCount = Mutex(0)
        let observer = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: context,
            queue: nil
        ) { _ in
            saveCount.withLock { $0 += 1 }
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        try work()
        return saveCount.withLock { $0 }
    }

    @Test("Catching up on several months confirms them all in one save")
    func catchUpSavesOnce() throws {
        let context = try makeContext()
        for month in 1...4 {
            insertMonth(year: 2025, month: month, in: context)
        }
        insertRule("Rent", startingOn: day(2025, 1, 2), repartition: [.needs: -800_00], automatic: true, in: context)
        try context.save()

        var confirmedCount = 0
        let saves = try countSaves(of: context) {
            confirmedCount = try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: true)
        }

        #expect(confirmedCount == 4)
        #expect(saves == 1)
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).count == 4)
    }

    @Test("Catching up with nothing due doesn't save")
    func catchUpWithNothingDueDoesNotSave() throws {
        let context = try makeContext()
        insertMonth(year: 2025, month: 4, in: context)
        insertRule("Gym", startingOn: day(2025, 4, 28), repartition: [.wants: -29_00], automatic: true, in: context)
        try context.save()

        let saves = try countSaves(of: context) {
            try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: true)
        }

        #expect(saves == 0)
    }

    @Test("Catching up resumes after the last automatic confirmation")
    func catchUpResumesAfterCheckpoint() throws {
        let context = try makeContext()
        for month in 1...4 {
            insertMonth(year: 2025, month: month, in: context)
        }
        let rule = insertRule("Rent", startingOn: day(2025, 1, 2), repartition: [.needs: -800_00], automatic: true, in: context)
        rule.lastAutoConfirmedDate = day(2025, 2, 2)
        try context.save()

        let confirmedCount = try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: true)

        let confirmedDates = try context.fetch(FetchDescriptor<TransactionGroup>()).compactMap(\.recurringOccurrenceDate).sorted()
        #expect(confirmedCount == 2)
        #expect(confirmedDates == [day(2025, 3, 2), day(2025, 4, 2)])
        #expect(rule.lastAutoConfirmedDate == day(2025, 4, 2))
    }
}
