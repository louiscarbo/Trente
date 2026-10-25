//
//  TransactionCSVFormatTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct TransactionCSVFormatTests {
    private let paris = TimeZone(identifier: "Europe/Paris")!
    private let european = TransactionCSVFormat(style: .european)

    private func row(title: String = "Groceries", note: String? = "Market") -> TransactionExportRow {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = paris
        return TransactionExportRow(
            date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 12))!,
            monthStartDate: calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!,
            title: title,
            type: .expense,
            category: .needs,
            amountCents: -12_50,
            currencyCode: "EUR",
            isRecurring: false,
            note: note,
            transactionID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        )
    }

    private func lines(_ csv: String) -> [String] {
        Array(csv.components(separatedBy: "\r\n").dropLast())
    }

    @Test("The European style uses semicolons and a decimal comma")
    func europeanStyle() {
        let csv = TransactionCSVBuilder.csv(from: [row()], format: european, timeZone: paris)

        #expect(lines(csv) == [
            "Date;Month;Title;Type;Category;Amount;Currency;Recurring;Note;Transaction ID",
            "2026-10-05;2026-10;Groceries;expense;Needs;-12,50;EUR;;Market;00000000-0000-0000-0000-000000000001"
        ])
    }

    @Test("A semicolon inside a field is quoted in the European style only")
    func quotesSeparator() {
        #expect(TransactionCSVBuilder.escaped("Rent; flat", separator: ";") == "\"Rent; flat\"")
        #expect(TransactionCSVBuilder.escaped("Rent, flat", separator: ";") == "Rent, flat")
        #expect(TransactionCSVBuilder.escaped("Rent; flat") == "Rent; flat")
    }

    @Test("Leaving notes out removes the Note column")
    func withoutNotes() {
        let format = TransactionCSVFormat(includesNotes: false)

        let csv = TransactionCSVBuilder.csv(from: [row()], format: format, timeZone: paris)

        #expect(lines(csv) == [
            "Date,Month,Title,Type,Category,Amount,Currency,Recurring,Transaction ID",
            "2026-10-05,2026-10,Groceries,expense,Needs,-12.50,EUR,,00000000-0000-0000-0000-000000000001"
        ])
    }

    @Test("The file uses the chosen format")
    func fileUsesFormat() {
        let file = TransactionsCSVFile(rows: [row()], fileName: "Trente 2026-10", format: european)

        let text = String(decoding: file.data.dropFirst(3), as: UTF8.self)

        #expect(text == TransactionCSVBuilder.csv(from: [row()], format: european))
    }
}
