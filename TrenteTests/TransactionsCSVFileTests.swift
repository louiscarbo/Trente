//
//  TransactionsCSVFileTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Trente

@Suite(.serialized)
struct TransactionsCSVFileTests {
    private let paris = TimeZone(identifier: "Europe/Paris")!
    private let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    private func month(_ year: Int, _ month: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = paris
        return calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }

    @discardableResult
    private func insertGroup(
        title: String,
        image: Data? = nil,
        in month: Month,
        context: ModelContext
    ) -> TransactionGroup {
        let group = TransactionGroup(title: title, type: .expense, month: month, note: nil, imageAttachmentData: image)
        context.insert(group)
        group.entries = [TransactionEntry(amountCents: -12_50, category: .needs, group: group)]
        month.transactionGroups.append(group)
        return group
    }

    private func rowsWithImage(in context: ModelContext) throws -> (rows: [TransactionExportRow], group: TransactionGroup) {
        let month = insertMonth(year: 2026, month: 10, in: context)
        let group = insertGroup(title: "Groceries", image: png, in: month, context: context)
        try context.save()
        let groupsWithImages = Set(try context.fetch(TransactionExportRow.groupsWithImagesDescriptor).map(\.persistentModelID))
        return (TransactionExportRow.rows(from: [month], groupsWithImages: groupsWithImages), group)
    }

    private func text(of data: Data) -> String {
        String(bytes: data.dropFirst(3), encoding: .utf8) ?? ""
    }

    private func makeFolder() throws -> URL {
        let folder = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    @Test("File data is UTF-8 with a byte order mark")
    func dataStartsWithByteOrderMark() throws {
        let data = TransactionsCSVFile(monthIDs: [], fileName: "Trente 2026-10").csvData(rows: [])

        #expect(data.starts(with: [0xEF, 0xBB, 0xBF]))
        let text = try #require(String(data: data.dropFirst(3), encoding: .utf8))
        #expect(text == TransactionCSVBuilder.csv(from: []))
    }

    @Test("A month file is named after its month")
    func monthFileName() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 3, in: context)

        #expect(TransactionsCSVFile.fileName(for: month) == "Trente 2026-03")
        #expect(TransactionsCSVFile(monthIDs: [month.id], fileName: "Trente 2026-03").csvFileName == "Trente 2026-03.csv")
    }

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

    @Test("An export with images is a zip, without the folder it was made from")
    func writesAZip() async throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        insertGroup(title: "Groceries", image: png, in: month, context: context)
        try context.save()
        let file = TransactionsCSVFile(monthIDs: [month.id], fileName: "Trente 2026-10", hasImages: true)

        let fileURL = try await file.write(from: context.container)
        let directory = fileURL.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(fileURL.lastPathComponent == "Trente 2026-10.zip")
        #expect(try Data(contentsOf: fileURL).starts(with: [0x50, 0x4B, 0x03, 0x04]))
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false)) == ["Trente 2026-10.zip"])
    }

    @Test(
        "Leaving images out, or having none, writes a plain CSV file with no Image column",
        arguments: [(includesImages: false, hasImages: true), (includesImages: true, hasImages: false)]
    )
    func writesACSV(includesImages: Bool, hasImages: Bool) async throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        insertGroup(title: "Groceries", image: png, in: month, context: context)
        try context.save()
        let file = TransactionsCSVFile(
            monthIDs: [month.id],
            fileName: "Trente 2026-10",
            format: TransactionCSVFormat(includesImages: includesImages),
            hasImages: hasImages
        )

        let fileURL = try await file.write(from: context.container)
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let records = csvRecords(text(of: try Data(contentsOf: fileURL)))
        #expect(fileURL.lastPathComponent == "Trente 2026-10.csv")
        let header = try #require(records.first)
        #expect(records.count == 2)
        #expect(!header.contains("Image"))
    }

    @Test("Rows come from the selected months only, with their images")
    func rowsComeFromSelectedMonths() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        let november = insertMonth(year: 2026, month: 11, in: context)
        let groceries = insertGroup(title: "Groceries", image: png, in: october, context: context)
        insertGroup(title: "Taxi", in: november, context: context)
        try context.save()
        let file = TransactionsCSVFile(monthIDs: [october.id], fileName: "Trente 2026-10")

        let rows = try file.rows(in: context)

        #expect(rows.map(\.transactionID) == [groceries.id])
        #expect(rows.map(\.imageSourceID) == [groceries.persistentModelID])
    }

    @Test("The export folder holds the CSV and the images it points to")
    func folderHoldsCSVAndImages() throws {
        let context = try makeContext()
        let (rows, group) = try rowsWithImage(in: context)
        let file = TransactionsCSVFile(monthIDs: [], fileName: "Trente 2026-10", hasImages: true)
        let directory = try makeFolder()
        defer { try? FileManager.default.removeItem(at: directory) }

        let folder = try file.writeFolder(rows: rows, in: directory, using: context)

        let csv = text(of: try Data(contentsOf: folder.appending(path: file.csvFileName)))
        let records = csvRecords(csv)
        let imageColumn = try #require(records.first?.firstIndex(of: "Image"))
        let imagePath = try #require(records.last?[imageColumn])
        let expectedName = TransactionExportImage.fileName(date: group.addedDate, title: "Groceries", transactionID: group.id, data: png)
        #expect(records.count == 2)
        #expect(imagePath == "Images/\(expectedName)")
        #expect(try Data(contentsOf: folder.appending(path: imagePath)) == png)
    }

    @Test("A new export removes the files of the previous one")
    func newExportRemovesPreviousFiles() throws {
        let file = TransactionsCSVFile(monthIDs: [], fileName: "Trente 2026-10")

        let first = try file.writeCSV(rows: [])
        let second = try file.writeCSV(rows: [])
        defer { try? FileManager.default.removeItem(at: second.deletingLastPathComponent()) }

        #expect(!FileManager.default.fileExists(atPath: first.path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: second.path(percentEncoded: false)))
    }
}
