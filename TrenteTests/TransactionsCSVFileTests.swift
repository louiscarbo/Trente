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
}
