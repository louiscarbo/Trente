//
//  SidebarSelectionTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 31/10/2026.
//

import Testing
import SwiftData
@testable import Trente

@Suite(.serialized)
struct SidebarSelectionTests {

    @Test("Deleting the month on display moves to the latest month")
    func leavesDeletedMonth() throws {
        let context = try makeContext()
        let june = insertMonth(year: 2026, month: 6, in: context)
        let july = insertMonth(year: 2026, month: 7, in: context)
        let october = insertMonth(year: 2026, month: 10, in: context)

        let selection = SidebarSelection.month(june).leaving([june, july], for: october)

        #expect(selection == .month(october))
    }
}
