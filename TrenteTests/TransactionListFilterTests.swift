//
//  TransactionListFilterTests.swift
//  TrenteTests
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@Suite(.serialized)
struct TransactionListFilterTests {
    private let calendar = Calendar.current

    private func date(_ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    @discardableResult
    private func insertGroup(
        _ title: String,
        on day: Int,
        entries: [BudgetCategory: Int],
        in month: Month,
        context: ModelContext
    ) -> DisplayableTransaction {
        let type: TransactionType = entries.values.reduce(0, +) < 0 ? .expense : .income
        let group = TransactionGroup(
            title: title,
            type: type,
            month: month,
            note: nil,
            imageAttachmentData: nil,
            addedDate: date(10, day, hour: 12)
        )
        context.insert(group)
        for (category, amountCents) in entries {
            context.insert(TransactionEntry(amountCents: amountCents, category: category, group: group))
        }
        return DisplayableTransaction(kind: .group(group))
    }

    private func sampleItems(in context: ModelContext) throws -> (month: Month, items: [DisplayableTransaction]) {
        let month = insertMonth(year: 2026, month: 10, in: context)
        let items = [
            insertGroup("Café", on: 3, entries: [.wants: -4_50], in: month, context: context),
            insertGroup("Rent", on: 1, entries: [.needs: -800_00], in: month, context: context),
            insertGroup("Salary", on: 25, entries: [.needs: 1_000_00, .wants: 500_00], in: month, context: context)
        ]
        try context.save()
        return (month, items)
    }

    @Test("A fresh filter keeps every transaction, newest first")
    func freshFilterKeepsEverything() throws {
        let context = try makeContext()
        let (month, items) = try sampleItems(in: context)

        let shown = TransactionListFilter(month: month).apply(to: items)

        #expect(shown.map(\.title) == ["Salary", "Café", "Rent"])
    }

    @Test("Search ignores case and accents")
    func searchIgnoresCaseAndAccents() throws {
        let context = try makeContext()
        let (month, items) = try sampleItems(in: context)
        var filter = TransactionListFilter(month: month)

        filter.searchText = "cafe"

        #expect(filter.apply(to: items).map(\.title) == ["Café"])
    }

    @Test("Filtering on a category keeps an income split across it")
    func categoryFilterKeepsSplitIncome() throws {
        let context = try makeContext()
        let (month, items) = try sampleItems(in: context)
        var filter = TransactionListFilter(month: month)

        filter.categories = [.wants]

        #expect(filter.apply(to: items).map(\.title) == ["Salary", "Café"])
    }

    @Test("Each sort order orders the transactions", arguments: SortOption.allCases)
    func sortOrders(sort: SortOption) throws {
        let context = try makeContext()
        let (month, items) = try sampleItems(in: context)
        var filter = TransactionListFilter(month: month)

        filter.sort = sort

        let expected: [String] = switch sort {
        case .dateAsc: ["Rent", "Café", "Salary"]
        case .dateDesc: ["Salary", "Café", "Rent"]
        case .amountAsc: ["Rent", "Café", "Salary"]
        case .amountDesc: ["Salary", "Café", "Rent"]
        case .titleAsc: ["Café", "Rent", "Salary"]
        case .titleDesc: ["Salary", "Rent", "Café"]
        }
        #expect(filter.apply(to: items).map(\.title) == expected)
    }

    @Test("Only dates and categories count as active filters")
    func activeFilters() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        var filter = TransactionListFilter(month: month)
        filter.searchText = "rent"
        filter.sort = .titleAsc
        #expect(!filter.isActive(for: month))

        var datedFilter = TransactionListFilter(month: month)
        datedFilter.firstDay = date(10, 5)
        #expect(datedFilter.isActive(for: month))

        var categoryFilter = TransactionListFilter(month: month)
        categoryFilter.categories = [.needs]
        #expect(categoryFilter.isActive(for: month))
    }

    @Test("Resetting clears dates and categories but keeps search and sort")
    func resetClearsOnlyFilters() throws {
        let context = try makeContext()
        let month = insertMonth(year: 2026, month: 10, in: context)
        var filter = TransactionListFilter(month: month)
        filter.firstDay = date(10, 5)
        filter.lastDay = date(10, 12)
        filter.categories = [.needs, .wants]
        filter.searchText = "rent"
        filter.sort = .amountAsc

        filter.reset(for: month)

        #expect(!filter.isActive(for: month))
        #expect(filter.firstDay == month.startDate)
        #expect(filter.lastDay == month.endDate())
        #expect(filter.categories.isEmpty)
        #expect(filter.searchText == "rent")
        #expect(filter.sort == .amountAsc)
    }

    @Test("The total adds up only the transactions shown")
    func totalOfShownTransactions() throws {
        let context = try makeContext()
        let (month, items) = try sampleItems(in: context)
        var filter = TransactionListFilter(month: month)
        filter.categories = [.needs]

        let shown = filter.apply(to: items)

        #expect(filter.totalCents(of: shown) == -800_00 + 1_500_00)
    }

    @Test func includesTheWholeLastDay() {
        let days = TransactionListFilter.days(from: date(10, 25), through: date(11, 24))

        #expect(days.contains(date(11, 24, hour: 23, minute: 59)))
        #expect(!days.contains(date(11, 25)))
    }

    @Test func includesTheWholeFirstDayWhenTheMonthStartedLaterThatDay() {
        let days = TransactionListFilter.days(from: date(10, 25, hour: 14, minute: 32), through: date(11, 24))

        #expect(days.contains(date(10, 25, hour: 9)))
        #expect(!days.contains(date(10, 24, hour: 23, minute: 59)))
    }

    @Test func monthEndDateKeepsItsLastDay() {
        let month = Month(
            startDate: date(10, 25, hour: 14),
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 0,
            idealRepartition: [:]
        )

        let days = TransactionListFilter.days(from: month.startDate, through: month.endDate())

        #expect(days.contains(date(11, 24, hour: 18)))
        #expect(days.lowerBound == month.dateInterval.start)
        #expect(days.upperBound == month.dateInterval.end)
    }

    @Test func emptyWhenTheRangeIsReversed() {
        let days = TransactionListFilter.days(from: date(11, 24), through: date(10, 25))

        #expect(days.isEmpty)
    }
}
