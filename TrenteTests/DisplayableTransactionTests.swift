//
//  DisplayableTransactionTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Trente

@Suite(.serialized)
struct DisplayableTransactionTests {

    @Test("Two wrappers of the same transaction share an id, so list rows keep their state")
    func groupIDIsStable() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        let group = TransactionGroup(title: "Coffee", type: .expense, month: month, note: nil, imageAttachmentData: nil)
        context.insert(group)
        try context.save()

        let first = DisplayableTransaction(kind: .group(group))
        let second = DisplayableTransaction(kind: .group(group))

        #expect(first.id == second.id)
    }

    @Test("Different transactions get different ids")
    func groupIDsDiffer() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        let coffee = TransactionGroup(title: "Coffee", type: .expense, month: month, note: nil, imageAttachmentData: nil)
        let lunch = TransactionGroup(title: "Lunch", type: .expense, month: month, note: nil, imageAttachmentData: nil)
        context.insert(coffee)
        context.insert(lunch)
        try context.save()

        #expect(DisplayableTransaction(kind: .group(coffee)).id != DisplayableTransaction(kind: .group(lunch)).id)
    }

    @Test("A recurring occurrence keeps the same id across recomputes")
    func occurrenceIDIsStable() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        let rule = RecurringTransactionRule(
            title: "Rent",
            frequency: .monthly,
            startDate: month.startDate,
            repartition: [.needs: -800_00],
            createdAt: month.startDate
        )
        context.insert(rule)
        try context.save()

        let first = RecurringTransactionOccurrence(rule: rule, date: month.startDate, month: month)
        let second = RecurringTransactionOccurrence(rule: rule, date: month.startDate, month: month)

        #expect(DisplayableTransaction(kind: .recurring(first)).id == DisplayableTransaction(kind: .recurring(second)).id)
    }
}
