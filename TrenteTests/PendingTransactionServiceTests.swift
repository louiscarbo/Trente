//
//  PendingTransactionServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@Suite(.serialized)
struct PendingTransactionServiceTests {

    private func insertPending(
        date: Date = Date(timeIntervalSince1970: 1_800_000_000),
        in context: ModelContext
    ) -> PendingTransaction {
        let pending = PendingTransaction(
            date: date,
            amountCents: -53_74,
            title: "Dia"
        )
        context.insert(pending)
        return pending
    }

    @Test("Validating creates the expense in the latest month and removes the pending item")
    func validateCreatesExpense() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 9, in: context)
        let latest = insertMonth(year: 2026, month: 10, in: context)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let pending = insertPending(date: date, in: context)
        var draft = TransactionGroupDraft(from: pending)
        draft.title = "Dia Express"
        draft.expenseCategory = .wants
        draft.note = "Snacks"

        try PendingTransactionService.shared.validate(pending, with: draft, in: context)

        let groups = try context.fetch(FetchDescriptor<TransactionGroup>())
        #expect(groups.count == 1)
        let group = try #require(groups.first)
        #expect(group.title == "Dia Express")
        #expect(group.type == .expense)
        #expect(group.note == "Snacks")
        #expect(group.addedDate == date)
        #expect(group.month?.id == latest.id)

        let entries = try context.fetch(FetchDescriptor<TransactionEntry>())
        #expect(entries.count == 1)
        #expect(entries.first?.amountCents == -53_74)
        #expect(entries.first?.category == .wants)

        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).isEmpty)
    }

    @Test("Validating files the expense in the month of its purchase date")
    func validateIntoPurchaseMonth() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        insertMonth(year: 2026, month: 11, in: context)
        let purchaseDate = Calendar.current.date(
            from: DateComponents(year: 2026, month: 10, day: 31, hour: 23, minute: 50)
        )!
        let pending = insertPending(date: purchaseDate, in: context)
        var draft = TransactionGroupDraft(from: pending)
        draft.expenseCategory = .needs

        try PendingTransactionService.shared.validate(pending, with: draft, in: context)

        let group = try #require(try context.fetch(FetchDescriptor<TransactionGroup>()).first)
        #expect(group.month?.id == october.id)
    }

    @Test("Validating without any month throws and keeps the pending item")
    func validateWithoutMonth() throws {
        let context = try makeContext()
        let pending = insertPending(in: context)
        let draft = TransactionGroupDraft(from: pending)

        #expect(throws: PendingTransactionError.noMonth) {
            try PendingTransactionService.shared.validate(pending, with: draft, in: context)
        }
        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).count == 1)
    }

    @Test("Discarding removes the pending item and creates nothing")
    func discardRemovesPending() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let pending = insertPending(in: context)

        try PendingTransactionService.shared.discard(pending, in: context)

        #expect(try context.fetch(FetchDescriptor<PendingTransaction>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).isEmpty)
    }

    @Test("A draft from a pending item mirrors it and requires a category")
    func draftFromPending() throws {
        let context = try makeContext()
        let pending = insertPending(in: context)

        var draft = TransactionGroupDraft(from: pending)
        #expect(draft.type == .expense)
        #expect(draft.title == "Dia")
        #expect(draft.expenseAmountCents == -53_74)
        #expect(draft.validate() == ["Select a category for the expense."])

        draft.expenseCategory = .needs
        #expect(draft.validate().isEmpty)
    }
}
