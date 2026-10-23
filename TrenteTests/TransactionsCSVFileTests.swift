//
//  TransactionsCSVFileTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import Testing
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
}
