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

    var fileNameWithExtension: String {
        "\(fileName).csv"
    }

    var data: Data {
        Self.byteOrderMark + Data(TransactionCSVBuilder.csv(from: rows).utf8)
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
}
