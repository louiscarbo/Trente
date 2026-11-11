//
//  RecurringTransactionRuleTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 04/11/2026.
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct RecurringTransactionRuleTests {
    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test("A rule's next date is given only while it's still pending")
    func nextDateIfPending() throws {
        let context = try makeContext()
        let rent = insertRule("Rent", startingOn: day(2025, 4, 1), in: context)
        let gym = insertRule("Gym", startingOn: day(2025, 4, 1), in: context)
        gym.endDate = day(2025, 5, 1)

        #expect(rent.nextDateIfPending(onOrAfter: day(2025, 6, 10)) == day(2025, 7, 1))
        #expect(gym.nextDateIfPending(onOrAfter: day(2025, 6, 10)) == nil)
        rent.skippedOccurrenceDates = [day(2025, 7, 1)]
        #expect(rent.nextDateIfPending(onOrAfter: day(2025, 6, 10)) == nil)
    }
}
