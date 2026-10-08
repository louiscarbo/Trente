//
//  MonthServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@Suite(.serialized)
struct MonthServiceTests {

    @Test("The latest month by start date is the current one")
    func latestMonth() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 8, in: context)
        let latest = insertMonth(year: 2026, month: 10, in: context)
        insertMonth(year: 2026, month: 9, in: context)

        let found = try MonthService.shared.latestMonth(in: context)

        #expect(found?.id == latest.id)
    }

    @Test("There is no latest month when none exist")
    func latestMonthWithoutMonths() throws {
        let context = try makeContext()

        #expect(try MonthService.shared.latestMonth(in: context) == nil)
    }
}
