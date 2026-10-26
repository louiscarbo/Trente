//
//  TransactionCSVBuilderTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct TransactionCSVBuilderTests {
    private let paris = TimeZone(identifier: "Europe/Paris")!
    private let headerLine = "Date,Month,Title,Type,Category,Amount,Currency,Recurring,Note,Transaction ID\r\n"

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 12,
        minute: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = paris
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components)!
    }

    private func row(
        title: String = "Groceries",
        date: Date? = nil,
        type: TransactionType = .expense,
        category: BudgetCategory = .needs,
        amountCents: Int = -12_50,
        isRecurring: Bool = false,
        note: String? = nil,
        transactionID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    ) -> TransactionExportRow {
        TransactionExportRow(
            date: date ?? self.date(2026, 10, 5),
            monthStartDate: self.date(2026, 10, 1, hour: 0),
            title: title,
            type: type,
            category: category,
            amountCents: amountCents,
            currencyCode: "EUR",
            isRecurring: isRecurring,
            note: note,
            transactionID: transactionID
        )
    }

    private func dataLines(of csv: String) -> [String] {
        Array(csv.components(separatedBy: "\r\n").dropFirst().dropLast())
    }

    private func dataRecords(of csv: String) -> [[String]] {
        Array(csvRecords(csv).dropFirst())
    }

    @Test("Empty input gives only the header")
    func emptyInputGivesHeader() {
        #expect(TransactionCSVBuilder.csv(from: [], timeZone: paris) == headerLine)
    }

    @Test("A row lists every column in order")
    func rowListsEveryColumn() {
        let csv = TransactionCSVBuilder.csv(
            from: [row(isRecurring: true, note: "Weekly")],
            timeZone: paris
        )

        #expect(csv == headerLine + "2026-10-05,2026-10,Groceries,expense,Needs,-12.50,EUR,yes,Weekly,00000000-0000-0000-0000-000000000001\r\n")
    }

    @Test("A non-recurring row without note leaves both columns empty")
    func emptyRecurringAndNote() {
        let lines = dataLines(of: TransactionCSVBuilder.csv(from: [row()], timeZone: paris))

        #expect(lines == ["2026-10-05,2026-10,Groceries,expense,Needs,-12.50,EUR,,,00000000-0000-0000-0000-000000000001"])
    }

    @Test(
        "Formats cents as a signed amount with a dot",
        arguments: [
            (0, "0.00"),
            (5, "0.05"),
            (-5, "-0.05"),
            (-50, "-0.50"),
            (100, "1.00"),
            (-12_50, "-12.50"),
            (1_234_567_89, "1234567.89"),
            (-9_999_999_999_99, "-9999999999.99"),
            (Int.max, "92233720368547758.07"),
            (Int.min, "-92233720368547758.08")
        ]
    )
    func formatsAmount(cents: Int, expected: String) {
        #expect(TransactionCSVBuilder.amountText(fromCents: cents) == expected)
    }

    @Test(
        "Quotes fields only when needed",
        arguments: [
            ("Plain", "Plain"),
            ("", ""),
            ("Rent, flat", "\"Rent, flat\""),
            ("The \"best\" pizza", "\"The \"\"best\"\" pizza\""),
            ("Line\nbreak", "\"Line\nbreak\""),
            ("Line\r\nbreak", "\"Line\r\nbreak\""),
            ("Carriage\rreturn", "\"Carriage\rreturn\""),
            ("Café ☕️", "Café ☕️")
        ]
    )
    func quotesFields(field: String, expected: String) {
        #expect(TransactionCSVBuilder.escaped(field) == expected)
    }

    @Test("Escapes titles and notes inside a row")
    func escapesInsideRow() throws {
        let records = dataRecords(
            of: TransactionCSVBuilder.csv(
                from: [row(title: "Dinner, \"Chez Paul\"", note: "With Anna\nand Tom")],
                timeZone: paris
            )
        )

        #expect(records.count == 1)
        let record = try #require(records.first)
        #expect(record.count == 10)
        #expect(record[2] == "Dinner, \"Chez Paul\"")
        #expect(record[8] == "With Anna\nand Tom")
    }

    @Test(
        "Dates around midnight use the given time zone",
        arguments: [(0, 0), (0, 1), (23, 59)]
    )
    func datesAroundMidnight(hour: Int, minute: Int) throws {
        let added = date(2026, 10, 1, hour: hour, minute: minute)
        let lines = dataLines(of: TransactionCSVBuilder.csv(from: [row(date: added)], timeZone: paris))

        let line = try #require(lines.first)
        #expect(line.hasPrefix("2026-10-01,2026-10,"))
    }

    @Test("Midnight in Paris is the previous day in UTC")
    func midnightInOtherTimeZone() throws {
        let added = date(2026, 10, 1, hour: 0)
        let lines = dataLines(of: TransactionCSVBuilder.csv(from: [row(date: added)], timeZone: .gmt))

        let line = try #require(lines.first)
        #expect(line.hasPrefix("2026-09-30,2026-09,"))
    }

    @Test("Month text pads the month")
    func monthTextPadsMonth() {
        #expect(TransactionCSVBuilder.monthText(for: date(2026, 3, 1, hour: 0), timeZone: paris) == "2026-03")
    }

    @Test("An income split gives one row per category")
    func incomeSplitGivesRows() {
        let salaryID = UUID()
        let rows = [
            row(title: "Salary", type: .income, category: .savingsAndDebts, amountCents: 400_00, transactionID: salaryID),
            row(title: "Salary", type: .income, category: .needs, amountCents: 1000_00, transactionID: salaryID),
            row(title: "Salary", type: .income, category: .wants, amountCents: 600_00, transactionID: salaryID)
        ]

        let records = dataRecords(of: TransactionCSVBuilder.csv(from: rows, timeZone: paris))

        #expect(records.count == 3)
        #expect(records.allSatisfy { record in record[9] == salaryID.uuidString && record[3] == "income" })
        #expect(records.map { record in record[4] } == ["Needs", "Wants", "Savings and Debts"])
        #expect(records.map { record in record[5] } == ["1000.00", "600.00", "400.00"])
    }

    @Test("Every row of an income split repeats the image path")
    func incomeSplitRepeatsImagePath() {
        let salaryID = UUID()
        let rows = [
            row(title: "Salary", type: .income, category: .needs, amountCents: 1000_00, transactionID: salaryID),
            row(title: "Salary", type: .income, category: .wants, amountCents: 600_00, transactionID: salaryID),
            row(title: "Taxi", date: date(2026, 10, 6), transactionID: UUID())
        ]
        let path = "Images/2026-10-05 Salary \(salaryID.uuidString.prefix(8)).jpg"

        let records = dataRecords(of: TransactionCSVBuilder.csv(from: rows, imagePaths: [salaryID: path], timeZone: paris))

        #expect(records.map { record in record[9] } == [path, path, ""])
    }

    @Test("Rows are sorted by date, then by title")
    func sortsByDateThenTitle() {
        let rows = [
            row(title: "Taxi", date: date(2026, 10, 7), transactionID: UUID()),
            row(title: "coffee", date: date(2026, 10, 5), transactionID: UUID()),
            row(title: "Bakery", date: date(2026, 10, 5), transactionID: UUID()),
            row(title: "Rent", date: date(2026, 10, 1), transactionID: UUID())
        ]

        let titles = dataRecords(of: TransactionCSVBuilder.csv(from: rows, timeZone: paris))
            .map { record in record[2] }

        #expect(titles == ["Rent", "Bakery", "coffee", "Taxi"])
    }

    @Test("Uses CRLF line endings, including after the last row")
    func usesCRLF() {
        let csv = TransactionCSVBuilder.csv(from: [row(), row(title: "Taxi")], timeZone: paris)

        #expect(csv.hasSuffix("\r\n"))
        #expect(csv.components(separatedBy: "\r\n").count == 4)
        #expect(!csv.replacingOccurrences(of: "\r\n", with: "").contains("\n"))
    }
}
