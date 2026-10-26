//
//  ExportMonthOptionTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct ExportMonthOptionTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()

    private func option(_ year: Int, _ month: Int) -> ExportMonthOption {
        ExportMonthOption(
            id: UUID(),
            name: "\(year)-\(month)",
            startDate: calendar.date(from: DateComponents(year: year, month: month, day: 1))!,
            transactionCount: 0
        )
    }

    @Test("Months are grouped by year, newest year and newest month first")
    func groupsByYearNewestFirst() {
        let options = [option(2025, 11), option(2026, 2), option(2025, 12), option(2026, 1)]

        let groups = ExportMonthOption.groupedByYear(options, calendar: calendar)

        #expect(groups.map(\.year) == [2026, 2025])
        #expect(groups.map { group in group.options.map(\.name) } == [["2026-2", "2026-1"], ["2025-12", "2025-11"]])
    }

    @Test("No months gives no groups")
    func emptyGivesNoGroups() {
        #expect(ExportMonthOption.groupedByYear([], calendar: calendar).isEmpty)
    }
}
