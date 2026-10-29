//
//  TransactionsCSVFile.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import SwiftData

struct TransactionsCSVFile: Sendable {
    private static let byteOrderMark = Data([0xEF, 0xBB, 0xBF])
    private static let exportsDirectory = URL.temporaryDirectory.appending(path: "Exports", directoryHint: .isDirectory)

    let monthIDs: [UUID]
    let fileName: String
    var format = TransactionCSVFormat()
    var hasImages = false

    var includesImages: Bool {
        format.includesImages && hasImages
    }

    var csvFileName: String {
        "\(fileName).csv"
    }

    @concurrent
    func write(from container: ModelContainer) async throws -> URL {
        let context = ModelContext(container)
        let rows = try rows(in: context)
        return includesImages ? try archive(rows: rows, using: context) : try writeCSV(rows: rows)
    }

    func csvData(rows: [TransactionExportRow], imagePaths: [UUID: String]? = nil) -> Data {
        Self.byteOrderMark + Data(TransactionCSVBuilder.csv(from: rows, format: format, imagePaths: imagePaths).utf8)
    }

    func rows(in context: ModelContext) throws -> [TransactionExportRow] {
        let monthIDs = monthIDs
        let months = try context.fetch(FetchDescriptor<Month>(predicate: #Predicate { month in monthIDs.contains(month.id) }))
        let groupsWithImages = try context.fetch(TransactionExportRow.groupsWithImagesDescriptor)
        return TransactionExportRow.rows(from: months, groupsWithImages: Set(groupsWithImages.map(\.persistentModelID)))
    }

    func writeFolder(rows: [TransactionExportRow], in directory: URL, using context: ModelContext) throws -> URL {
        let folder = directory.appending(path: fileName, directoryHint: .isDirectory)
        let imagesFolder = folder.appending(path: TransactionExportImage.folderName, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        let imagePaths = try TransactionExportImage.writeImages(of: rows, to: imagesFolder, in: context)
        let csvURL = folder.appending(path: csvFileName, directoryHint: .notDirectory)
        try csvData(rows: rows, imagePaths: imagePaths).write(to: csvURL, options: .atomic)
        return folder
    }

    func archive(rows: [TransactionExportRow], using context: ModelContext) throws -> URL {
        let directory = try Self.makeTemporaryDirectory()
        do {
            let folder = try writeFolder(rows: rows, in: directory, using: context)
            let archiveURL = directory.appending(path: "\(fileName).zip", directoryHint: .notDirectory)
            try Self.zipItem(at: folder, to: archiveURL)
            try? FileManager.default.removeItem(at: folder)
            return archiveURL
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func writeCSV(rows: [TransactionExportRow]) throws -> URL {
        let directory = try Self.makeTemporaryDirectory()
        do {
            let fileURL = directory.appending(path: csvFileName, directoryHint: .notDirectory)
            try csvData(rows: rows).write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    private static func makeTemporaryDirectory() throws -> URL {
        try? FileManager.default.removeItem(at: exportsDirectory)
        let directory = exportsDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func zipItem(at folder: URL, to destination: URL) throws {
        var coordinationError: NSError?
        var copyError: (any Error)?
        NSFileCoordinator().coordinate(readingItemAt: folder, options: .forUploading, error: &coordinationError) { zipURL in
            do {
                try FileManager.default.copyItem(at: zipURL, to: destination)
            } catch {
                copyError = error
            }
        }
        if let coordinationError {
            throw coordinationError
        }
        if let copyError {
            throw copyError
        }
    }
}

extension TransactionsCSVFile {
    static var allMonthsFileName: String {
        String(localized: "Trente All Months")
    }

    static func fileName(for month: Month) -> String {
        "Trente \(TransactionCSVBuilder.monthText(for: month.startDate))"
    }

    static func fileName(
        forMonthsStartingOn startDates: [Date],
        includesEveryMonth: Bool,
        timeZone: TimeZone = .current
    ) -> String {
        guard !includesEveryMonth, let first = startDates.min(), let last = startDates.max() else {
            return allMonthsFileName
        }
        let firstText = TransactionCSVBuilder.monthText(for: first, timeZone: timeZone)
        let lastText = TransactionCSVBuilder.monthText(for: last, timeZone: timeZone)
        return firstText == lastText ? "Trente \(firstText)" : "Trente \(firstText) – \(lastText)"
    }
}
