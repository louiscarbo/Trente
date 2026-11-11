//
//  TransactionGroupTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 04/11/2026.
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct TransactionGroupTests {
    private func insertTransaction(
        _ title: String,
        entries: [(cents: Int, category: BudgetCategory)],
        in month: Month,
        context: ModelContext
    ) -> TransactionGroup {
        let group = TransactionGroup(
            title: title,
            type: entries.map(\.cents).reduce(0, +) < 0 ? .expense : .income,
            month: month,
            note: nil,
            imageAttachmentData: nil,
            addedDate: month.startDate
        )
        context.insert(group)
        for entry in entries {
            context.insert(TransactionEntry(amountCents: entry.cents, category: entry.category, group: group))
        }
        return group
    }

    @Test("A category's total adds up its entries across transactions")
    func totalAmountCentsInCategory() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let groceries = insertTransaction(
            "Groceries",
            entries: [(-40_00, .needs), (-12_50, .wants)],
            in: april,
            context: context
        )
        let dinner = insertTransaction("Dinner", entries: [(-30_00, .wants)], in: april, context: context)
        let salary = insertTransaction("Salary", entries: [(100_00, .needs)], in: april, context: context)
        let groups = [groceries, dinner, salary]

        #expect(TransactionGroup.totalAmountCents(of: groups, in: .needs) == 60_00)
        #expect(TransactionGroup.totalAmountCents(of: groups, in: .wants) == -42_50)
        #expect(TransactionGroup.totalAmountCents(of: groups, in: .savingsAndDebts) == 0)
    }
}
