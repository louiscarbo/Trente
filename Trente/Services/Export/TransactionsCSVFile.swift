//
//  TransactionsCSVFile.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct TransactionsCSVFile: Transferable, Sendable {
    private static let byteOrderMark = Data([0xEF, 0xBB, 0xBF])

    let rows: [TransactionExportRow]
    let fileName: String
    var format = TransactionCSVFormat()

    var fileNameWithExtension: String {
        "\(fileName).csv"
    }

    var data: Data {
        Self.byteOrderMark + Data(TransactionCSVBuilder.csv(from: rows, format: format).utf8)
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let directory = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appending(path: file.fileNameWithExtension, directoryHint: .notDirectory)
            try file.data.write(to: fileURL, options: .atomic)
            return SentTransferredFile(fileURL)
        }
        .suggestedFileName { $0.fileNameWithExtension }
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
