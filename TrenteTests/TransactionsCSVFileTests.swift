//
//  TransactionsCSVFileTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import SwiftData
import Testing
import UniformTypeIdentifiers
@testable import Trente

struct TransactionsCSVFileTests {

    @Test("File data is UTF-8 with a byte order mark")
    func dataStartsWithByteOrderMark() throws {
        let file = TransactionsCSVFile(rows: [], fileName: "Trente 2026-10")

        #expect(file.data.starts(with: [0xEF, 0xBB, 0xBF]))
        let text = try #require(String(data: file.data.dropFirst(3), encoding: .utf8))
        #expect(text == TransactionCSVBuilder.csv(from: []))
    }

    @Test("A month file is named after its month")
    func monthFileName() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 3, in: context)

        #expect(TransactionsCSVFile.fileName(for: month) == "Trente 2026-03")
        #expect(TransactionsCSVFile(rows: [], fileName: "Trente 2026-03").fileNameWithExtension == "Trente 2026-03.csv")
    }

    private func month(_ year: Int, _ month: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = paris
        return calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }

    private let paris = TimeZone(identifier: "Europe/Paris")!

    @Test("Exporting every month gives the all-months name")
    func everyMonthFileName() {
        let name = TransactionsCSVFile.fileName(
            forMonthsStartingOn: [month(2026, 9), month(2026, 10)],
            includesEveryMonth: true,
            timeZone: paris
        )

        #expect(name == TransactionsCSVFile.allMonthsFileName)
    }

    @Test("A selection is named after its first and last month, whatever the order")
    func selectionFileName() {
        let name = TransactionsCSVFile.fileName(
            forMonthsStartingOn: [month(2026, 10), month(2026, 6), month(2026, 8)],
            includesEveryMonth: false,
            timeZone: paris
        )

        #expect(name == "Trente 2026-06 – 2026-10")
    }

    @Test("A single selected month gets the month page's name")
    func singleMonthSelectionFileName() {
        let name = TransactionsCSVFile.fileName(
            forMonthsStartingOn: [month(2026, 10)],
            includesEveryMonth: false,
            timeZone: paris
        )

        #expect(name == "Trente 2026-10")
    }

    private func rowsWithImage(in context: ModelContext) throws -> [TransactionExportRow] {
        let month = insertMonth(year: 2026, month: 10, in: context)
        let group = TransactionGroup(
            title: "Groceries",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        )
        context.insert(group)
        group.entries = [TransactionEntry(amountCents: -12_50, category: .needs, group: group)]
        month.transactionGroups.append(group)
        try context.save()
        let groupsWithImages = Set(try context.fetch(TransactionExportRow.groupsWithImagesDescriptor).map(\.persistentModelID))
        return TransactionExportRow.rows(from: [month], groupsWithImages: groupsWithImages)
    }

    @Test("An export with images is a zip file")
    func imagesMakeAZip() throws {
        let context = try makeContext()
        let file = TransactionsCSVFile(rows: try rowsWithImage(in: context), fileName: "Trente 2026-10")

        #expect(file.includesImages)
        #expect(file.contentType == .zip)
        #expect(file.fileNameWithExtension == "Trente 2026-10.zip")
        #expect(file.csvFileName == "Trente 2026-10.csv")
    }

    @Test("Leaving images out keeps a plain CSV file")
    func imagesLeftOutMakeACSV() throws {
        let context = try makeContext()
        let file = TransactionsCSVFile(
            rows: try rowsWithImage(in: context),
            fileName: "Trente 2026-10",
            format: TransactionCSVFormat(includesImages: false)
        )

        #expect(!file.includesImages)
        #expect(file.contentType == .commaSeparatedText)
        #expect(file.fileNameWithExtension == "Trente 2026-10.csv")
    }

    @Test("An export without images is a plain CSV file with no Image column")
    func noImagesMakeACSV() {
        let file = TransactionsCSVFile(rows: [], fileName: "Trente 2026-10")

        #expect(!file.includesImages)
        #expect(file.contentType == .commaSeparatedText)
        #expect(file.fileNameWithExtension == "Trente 2026-10.csv")
        #expect(!String(decoding: file.data, as: UTF8.self).contains("Image"))
    }

    @Test("The archive is a zip named after the export")
    func archiveIsAZip() async throws {
        let context = try makeContext()
        let file = TransactionsCSVFile(rows: try rowsWithImage(in: context), fileName: "Trente 2026-10")

        let archiveURL = try await file.archive(using: context.container)
        defer { try? FileManager.default.removeItem(at: archiveURL.deletingLastPathComponent()) }

        #expect(archiveURL.lastPathComponent == "Trente 2026-10.zip")
        #expect(try Data(contentsOf: archiveURL).starts(with: [0x50, 0x4B, 0x03, 0x04]))
    }
}
