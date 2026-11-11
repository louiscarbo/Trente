//
//  BatchDeleteServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 30/10/2026.
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct BatchDeleteServiceTests {
    private let service = BatchDeleteService.shared

    private struct SaveFailure: Error {}

    private struct Snapshot: Equatable {
        let months: [String]
        let groups: [String]
        let rules: [String]
        let pendingOccurrences: [String]

        init(of context: ModelContext) throws {
            let storedMonths = try context.fetch(FetchDescriptor<Month>(sortBy: [SortDescriptor(\.startDate)]))
            let storedRules = try context.fetch(FetchDescriptor<RecurringTransactionRule>(sortBy: [SortDescriptor(\.title)]))
            months = storedMonths.map { month in "\(month.startDate) \(month.transactionGroups.count)" }
            groups = try context.fetch(FetchDescriptor<TransactionGroup>())
                .map { group in
                    let rule = group.recurringRule?.title ?? "no rule"
                    return "\(group.title) \(group.totalAmountCents) \(String(describing: group.month?.startDate)) \(rule)"
                }
                .sorted()
            rules = storedRules.map { rule in "\(rule.title) \(rule.transactions.count)" }
            pendingOccurrences = storedMonths
                .flatMap { month in storedRules.flatMap { $0.pendingOccurrences(in: month) } }
                .map { occurrence in "\(occurrence.rule.title) \(occurrence.date)" }
                .sorted()
        }
    }

    private struct Budget {
        let context: ModelContext
        let march: Month
        let april: Month
        let may: Month
        let rent: RecurringTransactionRule
        let gym: RecurringTransactionRule
        let coffee: TransactionGroup
        let salary: TransactionGroup
        let paidRent: TransactionGroup
        let paidGym: TransactionGroup
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeBudget() throws -> Budget {
        let context = try makeContext()
        let march = insertMonth(year: 2025, month: 3, in: context)
        let april = insertMonth(year: 2025, month: 4, in: context)
        let may = insertMonth(year: 2025, month: 5, in: context)
        let rent = insertRule("Rent", startingOn: day(2025, 3, 2), in: context)
        let gym = insertRule("Gym", startingOn: day(2025, 3, 2), repartition: [.wants: -30_00], in: context)
        gym.lastAutoConfirmedDate = day(2025, 3, 2)
        gym.skippedOccurrenceDates = [day(2025, 5, 2)]

        let coffee = TransactionGroup(
            title: "Coffee",
            type: .expense,
            month: april,
            note: "With Paul",
            imageAttachmentData: Data(repeating: 7, count: 2048),
            addedDate: day(2025, 4, 10)
        )
        context.insert(coffee)
        context.insert(TransactionEntry(amountCents: -5_00, category: .wants, group: coffee))

        let salary = TransactionGroup(
            title: "Salary",
            type: .income,
            month: april,
            note: nil,
            imageAttachmentData: nil,
            addedDate: day(2025, 4, 1)
        )
        context.insert(salary)
        context.insert(TransactionEntry(amountCents: 1000_00, category: .needs, group: salary))
        context.insert(TransactionEntry(amountCents: 600_00, category: .wants, group: salary))
        context.insert(TransactionEntry(amountCents: 400_00, category: .savingsAndDebts, group: salary))
        try context.save()

        let paidRent = try recordedTransaction(of: rent, in: april, context: context)
        let paidGym = try recordedTransaction(of: gym, in: march, context: context)
        return Budget(
            context: context,
            march: march,
            april: april,
            may: may,
            rent: rent,
            gym: gym,
            coffee: coffee,
            salary: salary,
            paidRent: paidRent,
            paidGym: paidGym
        )
    }

    @Test("Deleting transactions in a batch ends like deleting them one at a time")
    func transactionsMatchSingleDelete() throws {
        let oneAtATime = try makeBudget()
        for group in [oneAtATime.coffee, oneAtATime.salary, oneAtATime.paidRent] {
            TransactionService.shared.delete(group: group, in: oneAtATime.context)
            try oneAtATime.context.save()
        }
        let batch = try makeBudget()

        try service.delete(groups: [batch.coffee, batch.salary, batch.paidRent], in: batch.context)

        let snapshot = try Snapshot(of: batch.context)
        #expect(snapshot == (try Snapshot(of: oneAtATime.context)))
        #expect(try batch.context.fetchCount(FetchDescriptor<TransactionEntry>()) == 1)
        #expect(batch.rent.pendingOccurrences(in: batch.april).count == 1)
    }

    @Test("Deleting a rule in a batch keeps past transactions with their amounts")
    func rulesKeepRecordedTransactions() throws {
        let budget = try makeBudget()

        try service.delete(rules: [budget.rent], in: budget.context)

        #expect(budget.paidRent.recurringRule == nil)
        #expect(budget.paidRent.recurringOccurrenceDate == day(2025, 4, 2))
        #expect(budget.paidRent.totalAmountCents == -800_00)
        #expect(budget.april.transactionGroups.contains(budget.paidRent))
        #expect(budget.gym.transactions == [budget.paidGym])
    }

    @Test("Deleting months in a batch ends like deleting them one at a time")
    func monthsMatchSingleDelete() throws {
        let oneAtATime = try makeBudget()
        for month in [oneAtATime.march, oneAtATime.april] {
            MonthService.shared.delete(month: month, in: oneAtATime.context)
            try oneAtATime.context.save()
        }
        let batch = try makeBudget()

        try service.delete(months: [batch.march, batch.april], in: batch.context)

        #expect(try Snapshot(of: batch.context) == (try Snapshot(of: oneAtATime.context)))
        #expect(try batch.context.fetchCount(FetchDescriptor<TransactionGroup>()) == 0)
        #expect(try batch.context.fetchCount(FetchDescriptor<TransactionEntry>()) == 0)
        #expect(try batch.context.fetchCount(FetchDescriptor<RecurringTransactionRule>()) == 2)
    }

    @Test("The latest month is never deleted by a batch")
    func latestMonthIsKept() throws {
        let budget = try makeBudget()

        try service.delete(months: [budget.april, budget.may], in: budget.context)

        let months = try budget.context.fetch(FetchDescriptor<Month>())
        #expect(Set(months) == [budget.march, budget.may])
    }

    @Test("A failed save puts everything back")
    func failedSaveRestoresEverything() throws {
        let budget = try makeBudget()
        let before = try Snapshot(of: budget.context)
        let failingSave: BatchDeleteService.Save = { _ in throw SaveFailure() }

        #expect(throws: SaveFailure.self) {
            try service.delete(groups: [budget.coffee, budget.paidRent], in: budget.context, save: failingSave)
        }
        #expect(throws: SaveFailure.self) {
            try service.delete(rules: [budget.rent, budget.gym], in: budget.context, save: failingSave)
        }
        #expect(throws: SaveFailure.self) {
            try service.delete(months: [budget.march, budget.april], in: budget.context, save: failingSave)
        }

        #expect(try Snapshot(of: budget.context) == before)
        #expect(budget.coffee.imageAttachmentData?.count == 2048)
        #expect(budget.paidRent.recurringRule == budget.rent)
        #expect(!budget.context.hasChanges)
    }

    @Test("A batch can run again after a failed save")
    func retriesAfterFailedSave() throws {
        let budget = try makeBudget()
        try? service.delete(groups: [budget.coffee], in: budget.context) { _ in
            throw SaveFailure()
        }

        try service.delete(groups: [budget.coffee], in: budget.context)

        let titles = try budget.context.fetch(FetchDescriptor<TransactionGroup>()).map(\.title)
        #expect(!titles.contains("Coffee"))
        #expect(titles.count == 3)
    }

    @Test("Months nobody read can be rolled back and deleted again")
    func retriesUnreadMonths() throws {
        let budget = try makeBudget()
        let context = ModelContext(budget.context.container)
        let april = try #require(context.fetch(FetchDescriptor<Month>(sortBy: [SortDescriptor(\.startDate)])).dropFirst().first)

        try? service.delete(months: [april], in: context) { _ in
            throw SaveFailure()
        }
        try service.delete(months: [april], in: context)

        #expect(try context.fetchCount(FetchDescriptor<Month>()) == 2)
    }

    @Test("Rules nobody read can be rolled back and deleted again")
    func retriesUnreadRules() throws {
        let budget = try makeBudget()
        let context = ModelContext(budget.context.container)
        let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())

        try? service.delete(rules: rules, in: context) { _ in
            throw SaveFailure()
        }
        try service.delete(rules: rules, in: context)

        #expect(try context.fetchCount(FetchDescriptor<RecurringTransactionRule>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<TransactionGroup>()) == 4)
    }

    @Test("A transaction already gone doesn't stop the rest of the batch")
    func skipsTransactionAlreadyDeleted() throws {
        let budget = try makeBudget()
        TransactionService.shared.delete(group: budget.coffee, in: budget.context)
        try budget.context.save()

        try service.delete(groups: [budget.coffee, budget.salary], in: budget.context)

        let titles = try budget.context.fetch(FetchDescriptor<TransactionGroup>()).map(\.title).sorted()
        #expect(titles == ["Gym", "Rent"])
    }
}
