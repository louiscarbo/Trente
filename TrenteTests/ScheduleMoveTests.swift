//
//  ScheduleMoveTests.swift
//  TrenteTests
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct ScheduleMoveTests {
    private let calendar = Calendar.current
    private let service = RecurringTransactionService.shared

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func insertRule(
        frequency: RecurrenceFrequency,
        startingOn startDate: Date,
        in context: ModelContext
    ) -> RecurringTransactionRule {
        let rule = RecurringTransactionRule(
            title: "Rent",
            frequency: frequency,
            startDate: startDate,
            repartition: [.needs: -800_00],
            createdAt: startDate
        )
        context.insert(rule)
        return rule
    }

    private func occurrence(
        of rule: RecurringTransactionRule,
        in month: Month
    ) throws -> RecurringTransactionOccurrence {
        try #require(service.pendingOccurrences(of: [rule], in: month).first)
    }

    @Test("Marking a transaction early offers its day as the new schedule")
    func earlyConfirmOffersMove() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule(frequency: .monthly, startingOn: day(2025, 1, 5), in: context)

        let moved = service.movedStartDate(for: try occurrence(of: rule, in: april), confirmedOn: day(2025, 4, 4, hour: 9))

        #expect(moved == day(2025, 4, 4))
    }

    @Test("Marking a transaction on its own day offers nothing")
    func sameDayConfirmOffersNothing() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule(frequency: .monthly, startingOn: day(2025, 1, 5), in: context)

        #expect(service.movedStartDate(for: try occurrence(of: rule, in: april), confirmedOn: day(2025, 4, 5, hour: 18)) == nil)
    }

    @Test("Catching up on an earlier month's transaction offers nothing")
    func catchUpOffersNothing() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule(frequency: .monthly, startingOn: day(2025, 1, 5), in: context)

        #expect(service.movedStartDate(for: try occurrence(of: rule, in: april), confirmedOn: day(2025, 5, 2)) == nil)
    }

    @Test("Marking a weekly transaction on another weekday offers that weekday")
    func weeklyConfirmOffersWeekday() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule(frequency: .weekly, startingOn: day(2025, 4, 16), in: context)

        let moved = service.movedStartDate(for: try occurrence(of: rule, in: april), confirmedOn: day(2025, 4, 15))

        #expect(moved == day(2025, 4, 15))
    }

    @Test("Moving the schedule keeps this month settled and moves the next ones")
    func moveKeepsThisMonthSettled() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let may = insertMonth(year: 2025, month: 5, in: context)
        let rule = insertRule(frequency: .monthly, startingOn: day(2025, 1, 5), in: context)
        try context.save()

        try service.confirm(try occurrence(of: rule, in: april), in: context, addedDate: day(2025, 4, 4))
        try service.move(rule, to: day(2025, 4, 4), in: context)

        #expect(service.pendingOccurrences(of: [rule], in: april).isEmpty)
        #expect(service.pendingOccurrences(of: [rule], in: may).map(\.date) == [day(2025, 5, 4)])
    }
}
