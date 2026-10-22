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

@Suite(.serialized)
struct RecurringTransactionsTests {
    private let calendar = Calendar.current
    private let service = RecurringTransactionService.shared

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func insertRule(
        _ title: String,
        startingOn startDate: Date,
        repartition: [BudgetCategory: Int],
        in context: ModelContext
    ) -> RecurringTransactionRule {
        let rule = RecurringTransactionRule(
            title: title,
            frequency: .monthly,
            startDate: startDate,
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
}
