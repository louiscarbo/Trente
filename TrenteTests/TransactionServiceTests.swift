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

    @Test("A recurring income starting today is recorded once")
    func recurringIncomeStartingTodayIsRecordedOnce() throws {
        let context = try makeContext()
        let today = Calendar.current.dateComponents([.year, .month], from: .now)
        let month = insertMonth(year: today.year!, month: today.month!, in: context)
        let request = TransactionCreationRequest()
        request.title = "Salary"
        request.type = .income
        request.amountCents = 2000_00
        request.repartition = [.needs: 2000_00]
        request.isRecurrent = true
        request.recurrenceStartDate = .now

        try TransactionService.shared.create(with: request, for: month, in: context)

        let rule = try #require(try context.fetch(FetchDescriptor<RecurringTransactionRule>()).first)
        let groups = try context.fetch(FetchDescriptor<TransactionGroup>())
        #expect(groups.count == 1)
        #expect(groups.first?.recurringRule?.persistentModelID == rule.persistentModelID)
        #expect(RecurringTransactionService.shared.pendingOccurrences(of: [rule], in: month).isEmpty)
    }
}
