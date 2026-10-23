//
//  TransactionServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 14/05/2026.
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct TransactionServiceTests {

    private func makeMonth(in context: ModelContext) -> Month {
        let eur = Currencies.currency(for: "EUR")!
        let month = Month(
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 1))!,
            currency: eur,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )
        context.insert(month)
        return month
    }

    @Test("Deleting a plain group removes it and its entries")
    func deletePlainGroup() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)

        let group = TransactionGroup(title: "Coffee", type: .expense, month: month, note: nil, imageAttachmentData: nil)
        context.insert(group)
        let entry = TransactionEntry(amountCents: -5_00, category: .wants, group: group)
        context.insert(entry)
        group.entries = [entry]
        month.transactionGroups = [group]
        try context.save()

        TransactionService.shared.delete(group: group, in: context)
        try context.save()

        let groups = try context.fetch(FetchDescriptor<TransactionGroup>())
        let entries = try context.fetch(FetchDescriptor<TransactionEntry>())
        #expect(groups.isEmpty)
        #expect(entries.isEmpty)
    }

    private func insertCurrentMonth(in context: ModelContext) -> Month {
        let today = Calendar.current.dateComponents([.year, .month], from: .now)
        return insertMonth(year: today.year!, month: today.month!, in: context)
    }

    private func recurringRequest(_ type: TransactionType, startingOn startDate: Date = .now) -> TransactionCreationRequest {
        let request = TransactionCreationRequest()
        request.isRecurrent = true
        request.recurrenceStartDate = startDate
        request.type = type
        switch type {
        case .income:
            request.title = "Salary"
            request.amountCents = 2000_00
            request.repartition = [.needs: 2000_00]
        case .expense:
            request.title = "Rent"
            request.amountCents = -800_00
            request.selectedCategory = .needs
        }
        return request
    }

    @Test("A recurring transaction starting today stays pending until confirmed")
    func recurringTransactionStartingTodayStaysPending() throws {
        let context = try makeContext()
        let month = insertCurrentMonth(in: context)

        try TransactionService.shared.create(with: recurringRequest(.income), for: month, in: context)

        let rule = try #require(try context.fetch(FetchDescriptor<RecurringTransactionRule>()).first)
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).isEmpty)
        let pending = RecurringTransactionService.shared.pendingOccurrences(of: [rule], in: month)
        #expect(pending.map(\.date) == [Calendar.current.startOfDay(for: .now)])
    }

    @Test("A recurring expense keeps its category and signed amount")
    func recurringExpenseKeepsCategoryAndAmount() throws {
        let context = try makeContext()
        let month = insertCurrentMonth(in: context)

        try TransactionService.shared.create(with: recurringRequest(.expense), for: month, in: context)

        let rule = try #require(try context.fetch(FetchDescriptor<RecurringTransactionRule>()).first)
        #expect(rule.repartition == [.needs: -800_00])
    }

    @Test("A recurring transaction starting in the future records nothing yet")
    func recurringTransactionStartingLaterRecordsNothing() throws {
        let context = try makeContext()
        let month = insertCurrentMonth(in: context)
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: .now)!

        try TransactionService.shared.create(with: recurringRequest(.expense, startingOn: nextWeek), for: month, in: context)

        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<RecurringTransactionRule>()).count == 1)
    }

    @Test("A recurring transaction cannot start in the past")
    func recurringTransactionCannotStartInPast() throws {
        let context = try makeContext()
        let month = insertCurrentMonth(in: context)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!

        #expect(throws: TransactionServiceError.recurrenceStartsInPast) {
            try TransactionService.shared.create(with: recurringRequest(.expense, startingOn: yesterday), for: month, in: context)
        }
        #expect(try context.fetch(FetchDescriptor<RecurringTransactionRule>()).isEmpty)
    }
}
