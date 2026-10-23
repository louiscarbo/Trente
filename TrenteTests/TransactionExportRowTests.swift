//
//  TransactionExportRowTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Trente

@Suite(.serialized)
struct TransactionExportRowTests {

    @discardableResult
    private func insertGroup(
        title: String,
        type: TransactionType,
        amounts: [BudgetCategory: Int],
        in month: Month,
        context: ModelContext
    ) -> TransactionGroup {
        let group = TransactionGroup(title: title, type: type, month: month, note: "Note \(title)", imageAttachmentData: nil)
        context.insert(group)
        group.entries = amounts.map { category, amountCents in
            TransactionEntry(amountCents: amountCents, category: category, group: group)
        }
        month.transactionGroups.append(group)
        return group
    }

    @Test("Maps each entry of each month to a row")
    func mapsEntriesToRows() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        let november = insertMonth(year: 2026, month: 11, in: context)
        let coffee = insertGroup(title: "Coffee", type: .expense, amounts: [.wants: -3_50], in: october, context: context)
        let salary = insertGroup(
            title: "Salary",
            type: .income,
            amounts: [.needs: 1000_00, .wants: 600_00, .savingsAndDebts: 400_00],
            in: november,
            context: context
        )
        try context.save()

        let rows = TransactionExportRow.rows(from: [october, november])

        #expect(rows.count == 4)
        let coffeeRow = try #require(rows.first { $0.transactionID == coffee.id })
        #expect(coffeeRow.title == "Coffee")
        #expect(coffeeRow.type == .expense)
        #expect(coffeeRow.category == .wants)
        #expect(coffeeRow.amountCents == -3_50)
        #expect(coffeeRow.currencyCode == "EUR")
        #expect(coffeeRow.note == "Note Coffee")
        #expect(coffeeRow.date == coffee.addedDate)
        #expect(coffeeRow.monthStartDate == october.startDate)
        #expect(!coffeeRow.isRecurring)

        let salaryRows = rows.filter { $0.transactionID == salary.id }
        #expect(salaryRows.map(\.amountCents).sorted() == [400_00, 600_00, 1000_00])
        #expect(salaryRows.allSatisfy { $0.monthStartDate == november.startDate })
    }

    @Test("A transaction from a recurring one stays recurring after the rule is gone")
    func recurringFlagUsesOccurrenceDate() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        let rent = insertGroup(title: "Rent", type: .expense, amounts: [.needs: -800_00], in: month, context: context)
        rent.recurringOccurrenceDate = month.startDate
        try context.save()

        let rows = TransactionExportRow.rows(from: [month])

        #expect(rows.map(\.isRecurring) == [true])
    }

    @Test("A month without transactions gives no rows")
    func emptyMonthGivesNoRows() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)

        #expect(TransactionExportRow.rows(from: [month]).isEmpty)
    }
}
