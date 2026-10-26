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
        image: Data? = nil,
        in month: Month,
        context: ModelContext
    ) -> TransactionGroup {
        let group = TransactionGroup(title: title, type: type, month: month, note: "Note \(title)", imageAttachmentData: image)
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
    func recurringFlagSurvivesRuleDeletion() throws {
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
        let rent = insertGroup(title: "Rent", type: .expense, amounts: [.needs: -800_00], in: month, context: context)
        rent.recurringRule = rule
        rent.recurringOccurrenceDate = month.startDate
        try context.save()

        RecurringTransactionService.shared.delete(rule: rule, in: context)
        try context.save()

        #expect(rent.recurringRule == nil)
        #expect(TransactionExportRow.rows(from: [month]).map(\.isRecurring) == [true])
    }

    @Test("A month without transactions gives no rows")
    func emptyMonthGivesNoRows() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)

        #expect(TransactionExportRow.rows(from: [month]).isEmpty)
    }

    private let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])

    private func groupsWithImages(in context: ModelContext) throws -> Set<PersistentIdentifier> {
        Set(try context.fetch(TransactionExportRow.groupsWithImagesDescriptor).map(\.persistentModelID))
    }

    @Test("Rows of a transaction with an image point to it, split incomes included")
    func rowsReferenceImages() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        let coffee = insertGroup(title: "Coffee", type: .expense, amounts: [.wants: -3_50], in: month, context: context)
        let salary = insertGroup(
            title: "Salary",
            type: .income,
            amounts: [.needs: 1000_00, .wants: 600_00],
            image: jpeg,
            in: month,
            context: context
        )
        try context.save()

        let rows = TransactionExportRow.rows(from: [month], groupsWithImages: try groupsWithImages(in: context))

        #expect(rows.filter { $0.transactionID == salary.id }.map(\.imageSourceID) == [salary.persistentModelID, salary.persistentModelID])
        let coffeeRow = try #require(rows.first { $0.transactionID == coffee.id })
        #expect(coffeeRow.imageSourceID == nil)
        #expect(TransactionExportImage.rowsWithImages(in: rows).map(\.transactionID) == [salary.id])
    }

    @Test("Rows built without the image list point to no image")
    func rowsWithoutImageList() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        insertGroup(title: "Coffee", type: .expense, amounts: [.wants: -3_50], image: jpeg, in: month, context: context)
        try context.save()

        #expect(TransactionExportRow.rows(from: [month]).allSatisfy { $0.imageSourceID == nil })
    }

    @Test("Writes one file per transaction image and skips images removed since")
    func writesImages() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        let salary = insertGroup(
            title: "Salary",
            type: .income,
            amounts: [.needs: 1000_00, .wants: 600_00],
            image: jpeg,
            in: month,
            context: context
        )
        let taxi = insertGroup(title: "Taxi", type: .expense, amounts: [.wants: -20_00], image: jpeg, in: month, context: context)
        try context.save()
        let rows = TransactionExportRow.rows(from: [month], groupsWithImages: try groupsWithImages(in: context))
        taxi.imageAttachmentData = nil
        try context.save()
        let folder = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let paths = try TransactionExportImage.writeImages(of: rows, to: folder, from: context.container)

        let fileName = TransactionExportImage.fileName(date: salary.addedDate, title: "Salary", transactionID: salary.id, data: jpeg)
        #expect(paths == [salary.id: "Images/\(fileName)"])
        #expect(try Data(contentsOf: folder.appending(path: fileName)) == jpeg)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false)) == [fileName])
    }
}
