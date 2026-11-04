//
//  TrenteVingtImporterTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Trente

@Suite(.serialized)
struct TrenteVingtImporterTests {
    private let calendar = Calendar.current
    private var now: Date { date(2026, 10, 30) }
    private var importer: TrenteVingtImporter { TrenteVingtImporter(calendar: calendar, now: now) }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func startOfDay(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.startOfDay(for: date(year, month, day))
    }

    private func makeMonth(
        monthNumber: Int = 10,
        year: Int = 2026,
        creationDate: Date? = nil,
        budget: Double = 2000,
        currencyCode: String = "EUR",
        transactions: [TrenteVingtExport.Transaction] = []
    ) -> TrenteVingtExport.Month {
        TrenteVingtExport.Month(
            id: UUID(),
            monthNumber: monthNumber,
            creationDate: creationDate ?? date(year, monthNumber, 1),
            budget: budget,
            needsPercentage: 50,
            wantsPercentage: 30,
            savingsPercentage: 20,
            currencyCode: currencyCode,
            transactions: transactions
        )
    }

    private func makeRule(
        frequency: RecurrenceFrequency = .monthly,
        day: Int? = 5,
        startingDate: Date? = nil
    ) -> TrenteVingtExport.RecurringTransaction {
        TrenteVingtExport.RecurringTransaction(
            id: UUID(),
            title: "Rent",
            amount: -800,
            category: .needs,
            frequency: frequency,
            day: day,
            startingDate: startingDate
        )
    }

    private func makeExport(
        monthStartDay: Int = 1,
        months: [TrenteVingtExport.Month] = [],
        rules: [TrenteVingtExport.RecurringTransaction] = []
    ) -> TrenteVingtExport {
        TrenteVingtExport(monthStartDay: monthStartDay, months: months, recurringTransactions: rules)
    }

    private func transaction(_ title: String = "Coffee", on date: Date) -> TrenteVingtExport.Transaction {
        TrenteVingtExport.Transaction(title: title, amount: -3, date: date, category: .wants)
    }

    @Test("Reads the file TrenteVingt writes")
    func decodesExportFile() throws {
        let json = """
            {"exportDate":"2026-10-30T10:00:00Z","formatVersion":1,"monthStartDay":1,
            "months":[{"budget":1500.5,"creationDate":"2026-10-01T08:00:00Z","currencyCode":"CLP",
            "id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","monthNumber":10,"needsPercentage":50,
            "savingsPercentage":20,"transactions":[{"amount":-12.5,"category":"savingsAndDebts",
            "date":"2026-10-03T09:30:00Z","title":"Bus"}],"wantsPercentage":30}],
            "recurringTransactions":[{"amount":-800,"category":"needs","day":5,"frequency":"monthly",
            "id":"7F9619FF-8B86-D011-B42D-00C04FC964FF","title":"Rent"}]}
            """

        let export = try TrenteVingtExport.decode(from: Data(json.utf8))

        #expect(export.months.first?.currencyCode == "CLP")
        #expect(export.months.first?.transactions.first?.category == .savingsAndDebts)
        #expect(export.recurringTransactions.first?.frequency == .monthly)
    }

    @Test("A month keeps its id, currency and budget, and its budget becomes an income split like TrenteVingt")
    func importsMonthWithBudgetIncome() throws {
        let context = try makeContext()
        let exportedMonth = makeMonth(budget: 2000, currencyCode: "USD")

        let summary = try importer.importData(makeExport(months: [exportedMonth]), into: context)

        let month = try #require(try context.fetch(FetchDescriptor<Month>()).first)
        #expect(summary.monthCount == 1)
        #expect(month.id == exportedMonth.id)
        #expect(month.currency.isoCode == "USD")
        #expect(month.idealRepartition == [.needs: 1000_00, .wants: 600_00, .savingsAndDebts: 400_00])
        let income = try #require(month.transactionGroups.first)
        #expect(income.type == .income)
        #expect(income.totalAmountCents == 2000_00)
    }

    @Test("Expenses keep their category and sign, incomes are split like the month")
    func importsTransactions() throws {
        let context = try makeContext()
        let exportedMonth = makeMonth(budget: 0, transactions: [
            .init(title: "Groceries", amount: -42.5, date: date(2026, 10, 3), category: .needs),
            .init(title: "Gift", amount: 100, date: date(2026, 10, 4), category: .income)
        ])

        let summary = try importer.importData(makeExport(months: [exportedMonth]), into: context)

        let groups = try context.fetch(FetchDescriptor<TransactionGroup>(sortBy: [SortDescriptor(\.addedDate)]))
        #expect(summary.transactionCount == 2)
        #expect(groups.map(\.type) == [.expense, .income])
        #expect(groups[0].entries.map(\.amountCents) == [-42_50])
        #expect(groups[0].entries.map(\.category) == [.needs])
        #expect(groups[1].totalAmountCents == 100_00)
        #expect(groups[1].entries.count == 3)
    }

    @Test("The currency code in the file is the one used, even one TrenteVingt doesn't offer itself")
    func readsCurrencyCodeFromTheFile() throws {
        let context = try makeContext()

        try importer.importData(makeExport(months: [makeMonth(budget: 1200, currencyCode: "CLP")]), into: context)

        let month = try #require(try context.fetch(FetchDescriptor<Month>()).first)
        #expect(month.currency.isoCode == "CLP")
        #expect(month.idealBudgetCents == 1200_00)
    }

    @Test("A month in a currency Trente doesn't know is skipped and counted, never moved to another currency")
    func skipsUnknownCurrency() throws {
        let context = try makeContext()
        let exportedMonth = makeMonth(currencyCode: "XXX", transactions: [transaction(on: date(2026, 10, 3))])

        let summary = try importer.importData(makeExport(months: [exportedMonth]), into: context)

        #expect(try context.fetchCount(FetchDescriptor<Month>()) == 0)
        #expect(summary.skippedMonthCount == 1)
        #expect(summary.skippedTransactionCount == 1)
        #expect(summary.skipNote != nil)
    }

    @Test("A month overlapping one in Trente is skipped and counted, and the existing month isn't touched")
    func skipsOverlappingMonth() throws {
        let context = try makeContext()
        let existingMonth = insertMonth(year: 2026, month: 10, in: context)
        let existingID = existingMonth.id
        let overlapping = makeMonth(monthNumber: 10, currencyCode: "USD", transactions: [transaction(on: date(2026, 10, 3))])
        let free = makeMonth(monthNumber: 9)

        let summary = try importer.importData(makeExport(months: [overlapping, free]), into: context)

        let months = try context.fetch(FetchDescriptor<Month>(sortBy: [SortDescriptor(\.startDate)]))
        #expect(months.count == 2)
        #expect(months.last?.id == existingID)
        #expect(months.last?.currency.isoCode == "EUR")
        #expect(months.last?.transactionGroups.isEmpty == true)
        #expect(summary.monthCount == 1)
        #expect(summary.skippedMonthCount == 1)
        #expect(summary.skippedTransactionCount == 1)
    }

    @Test("Two months of the export on the same dates never overlap")
    func skipsOverlapInsideTheExport() throws {
        let context = try makeContext()

        let summary = try importer.importData(makeExport(months: [makeMonth(), makeMonth()]), into: context)

        #expect(try context.fetchCount(FetchDescriptor<Month>()) == 1)
        #expect(summary.skippedMonthCount == 1)
    }

    @Test("Importing twice adds nothing and reports nothing as skipped")
    func importingTwiceAddsNothing() throws {
        let context = try makeContext()
        let export = makeExport(
            months: [makeMonth(transactions: [transaction(on: date(2026, 10, 3))])],
            rules: [makeRule()]
        )

        try importer.importData(export, into: context)
        let secondPreview = try importer.preview(of: export, in: context)
        try importer.importData(export, into: context)

        #expect(secondPreview == TrenteVingtImportSummary())
        #expect(try context.fetchCount(FetchDescriptor<Month>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<TransactionGroup>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<RecurringTransactionRule>()) == 1)
    }

    @Test("The preview changes nothing and matches the import")
    func previewMatchesImport() throws {
        let context = try makeContext()
        let export = makeExport(months: [makeMonth(transactions: [transaction(on: date(2026, 10, 3))])], rules: [makeRule()])

        let preview = try importer.preview(of: export, in: context)

        #expect(try context.fetchCount(FetchDescriptor<Month>()) == 0)
        #expect(try importer.importData(export, into: context) == preview)
    }

    @Test("A month starts on its named month, in the year of its transactions")
    func startDateFromTransactions() {
        let exportedMonth = makeMonth(monthNumber: 1, transactions: [transaction(on: date(2025, 1, 10))])

        #expect(importer.startDate(of: exportedMonth, startDay: 1) == startOfDay(2025, 1, 1))
    }

    @Test("With a custom start day, a month starts where its transactions are")
    func startDateWithCustomDay() {
        let exportedMonth = makeMonth(monthNumber: 10, transactions: [
            transaction(on: date(2026, 9, 26)),
            transaction(on: date(2026, 10, 20))
        ])

        #expect(importer.startDate(of: exportedMonth, startDay: 25) == startOfDay(2026, 9, 25))
    }

    @Test("With a custom start day, an empty month starts where it was created, not a month later")
    func emptyMonthWithCustomDay() {
        let exportedMonth = makeMonth(monthNumber: 11, creationDate: date(2026, 10, 25))

        #expect(importer.startDate(of: exportedMonth, startDay: 25) == startOfDay(2026, 10, 25))
    }

    @Test("An empty month never pushes out the month after it")
    func emptyMonthKeepsNextMonth() throws {
        let context = try makeContext()
        let emptyMonth = makeMonth(monthNumber: 11, creationDate: date(2026, 10, 25))
        let nextMonth = makeMonth(
            monthNumber: 12,
            creationDate: date(2026, 11, 25),
            transactions: [transaction(on: date(2026, 11, 28))]
        )

        let summary = try importer.importData(makeExport(monthStartDay: 25, months: [emptyMonth, nextMonth]), into: context)

        #expect(summary.monthCount == 2)
        #expect(summary.skippedMonthCount == 0)
    }

    @Test("Rules keep their id and schedule, and never reach back before the import")
    func importsRules() throws {
        let context = try makeContext()
        let monthlyRule = makeRule(frequency: .monthly, day: 5)
        let weeklyRule = makeRule(frequency: .weekly, day: 1)
        let yearlyRule = makeRule(frequency: .yearly, day: nil, startingDate: date(2024, 3, 15))
        let invalidRule = makeRule(frequency: .monthly, day: nil)

        let summary = try importer.importData(
            makeExport(rules: [monthlyRule, weeklyRule, yearlyRule, invalidRule]),
            into: context
        )

        let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        let rule = { (id: UUID) in rules.first { $0.id == id } }
        #expect(summary.recurringTransactionCount == 3)
        #expect(rule(monthlyRule.id)?.startDate == startOfDay(2026, 1, 5))
        #expect(rule(weeklyRule.id)?.startDate == startOfDay(2026, 10, 26))
        #expect(rule(yearlyRule.id)?.startDate == startOfDay(2024, 3, 15))
        #expect(rule(monthlyRule.id)?.repartition == [.needs: -800_00])
        #expect(rule(monthlyRule.id)?.createdAt == now)
    }

    @Test("Splitting an odd amount in two never leaves a negative share")
    func splitNeverGoesNegative() {
        var exportedMonth = makeMonth()
        exportedMonth.needsPercentage = 50
        exportedMonth.wantsPercentage = 50
        exportedMonth.savingsPercentage = 0

        let split = importer.split(1234_57, like: exportedMonth)

        #expect(split[.needs] == 617_29)
        #expect(split[.wants] == 617_28)
        #expect(split[.savingsAndDebts] == 0)
    }

    @Test("Absurd amounts and percentages in a chosen file are ignored instead of crashing")
    func ignoresAbsurdValues() throws {
        let context = try makeContext()
        var exportedMonth = makeMonth(budget: 1e300, transactions: [
            .init(title: "Huge", amount: -1e300, date: date(2026, 10, 3), category: .needs),
            .init(title: "Coffee", amount: 5, date: date(2026, 10, 4), category: .income)
        ])
        exportedMonth.needsPercentage = 1e300
        exportedMonth.wantsPercentage = -1e300
        var rule = makeRule()
        rule.amount = -1e300
        let export = makeExport(months: [exportedMonth], rules: [rule])

        let preview = try importer.preview(of: export, in: context)
        try importer.importData(export, into: context)

        #expect(preview.recurringTransactionCount == 0)
        #expect(try context.fetchCount(FetchDescriptor<TransactionGroup>()) == 1)
    }

    @Test("A currency without a minor unit splits into whole units")
    func splitKeepsWholeUnits() {
        let split = importer.split(1001_00, like: makeMonth(currencyCode: "JPY"))

        #expect(split == [.needs: 501_00, .wants: 300_00, .savingsAndDebts: 200_00])
    }

    @Test("Splitting keeps every cent")
    func splitKeepsEveryCent() {
        let split = importer.split(1000_01, like: makeMonth())

        #expect(split.values.reduce(0, +) == 1000_01)
    }
}
