//
//  TransactionsCSVFile.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import CoreTransferable
import Foundation
import SwiftData
import UniformTypeIdentifiers

struct TransactionsCSVFile: Transferable, Sendable {
    private static let byteOrderMark = Data([0xEF, 0xBB, 0xBF])

    let rows: [TransactionExportRow]
    let fileName: String
    var format = TransactionCSVFormat()

    var includesImages: Bool {
        format.includesImages && rows.contains { row in row.imageSourceID != nil }
    }

    var contentType: UTType {
        includesImages ? .zip : .commaSeparatedText
    }

    var fileNameWithExtension: String {
        includesImages ? "\(fileName).zip" : csvFileName
    }

    var csvFileName: String {
        "\(fileName).csv"
    }

    var data: Data {
        csvData(imagePaths: nil)
    }

    func csvData(imagePaths: [UUID: String]?) -> Data {
        Self.byteOrderMark + Data(TransactionCSVBuilder.csv(from: rows, format: format, imagePaths: imagePaths).utf8)
    }

    func archive(using container: ModelContainer) async throws -> URL {
        let directory = try Self.makeTemporaryDirectory()
        let folder = directory.appending(path: fileName, directoryHint: .isDirectory)
        let imagesFolder = folder.appending(path: TransactionExportImage.folderName, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        let imagePaths = try await MainActor.run {
            try TransactionExportImage.writeImages(of: rows, to: imagesFolder, from: container)
        }
        let csvURL = folder.appending(path: csvFileName, directoryHint: .notDirectory)
        try csvData(imagePaths: imagePaths).write(to: csvURL, options: .atomic)
        let archiveURL = directory.appending(path: "\(fileName).zip", directoryHint: .notDirectory)
        try Self.zipItem(at: folder, to: archiveURL)
        try? FileManager.default.removeItem(at: folder)
        return archiveURL
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .zip) { file in
            let container = try await MainActor.run { try TrenteContainer.shared.get() }
            let archiveURL = try await file.archive(using: container)
            return SentTransferredFile(archiveURL)
        }
        .suggestedFileName { $0.fileNameWithExtension }
        .exportingCondition { file in file.includesImages }

        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let fileURL = try Self.makeTemporaryDirectory().appending(path: file.csvFileName, directoryHint: .notDirectory)
            try file.data.write(to: fileURL, options: .atomic)
            return SentTransferredFile(fileURL)
        }
        .suggestedFileName { $0.fileNameWithExtension }
        .exportingCondition { file in !file.includesImages }
    }

    private static func makeTemporaryDirectory() throws -> URL {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
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
