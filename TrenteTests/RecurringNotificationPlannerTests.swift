//
//  RecurringNotificationPlannerTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct RecurringNotificationPlannerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()
    private let euro = Currencies.currency(for: "EUR")!
    private let service = RecurringTransactionService.shared

    private var planner: RecurringNotificationPlanner {
        RecurringNotificationPlanner(calendar: calendar)
    }

    private var now: Date {
        day(2025, 4, 10, hour: 8)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @discardableResult
    private func insertRule(
        _ title: String,
        frequency: RecurrenceFrequency = .monthly,
        startingOn startDate: Date,
        endingOn endDate: Date? = nil,
        createdAt: Date? = nil,
        repartition: [BudgetCategory: Int] = [.needs: -800_00],
        automatic: Bool = false,
        in context: ModelContext
    ) -> RecurringTransactionRule {
        let rule = RecurringTransactionRule(
            title: title,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            autoConfirm: automatic,
            repartition: repartition,
            createdAt: createdAt ?? startDate
        )
        context.insert(rule)
        return rule
    }

    private func occurrence(
        of rule: RecurringTransactionRule,
        on date: Date,
        in month: Month
    ) -> RecurringTransactionOccurrence {
        RecurringTransactionOccurrence(
            rule: rule,
            date: date,
            month: month
        )
    }

    @Test("A manual occurrence fires at nine on its due day")
    func firesAtNineOnTheDueDay() throws {
        let context = try makeContext()
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        try context.save()

        let requests = planner.requests(for: [rule], currency: euro, now: now)

        #expect(requests.count == 1)
        let request = try #require(requests.first)
        #expect(request.occurrenceDate == day(2025, 4, 15))
        #expect(request.fireDate == day(2025, 4, 15, hour: 9))
        #expect(request.kind == .due)
        #expect(request.body == String(localized: "Due today. Open Trente to mark it as paid."))
        #expect(request.ruleID == rule.id)
    }

    @Test("Today's occurrence is left out once nine has passed")
    func skipsTodayAfterNine() throws {
        let context = try makeContext()
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        try context.save()

        let requests = planner.requests(for: [rule], currency: euro, now: day(2025, 4, 15, hour: 14))

        #expect(requests.map(\.fireDate) == [day(2025, 5, 15, hour: 9)])
    }

    @Test("The chosen reminder time replaces nine")
    func usesChosenReminderTime() throws {
        let context = try makeContext()
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        try context.save()
        let planner = RecurringNotificationPlanner(reminderTime: ReminderTime(hour: 18, minute: 30), calendar: calendar)

        let request = try #require(planner.requests(for: [rule], currency: euro, now: now).first)

        let expected = try #require(calendar.date(from: DateComponents(year: 2025, month: 4, day: 15, hour: 18, minute: 30)))
        #expect(request.fireDate == expected)
    }

    @Test("Nothing is planned before the rule's creation day")
    func neverBeforeRuleCreation() throws {
        let context = try makeContext()
        let planner = RecurringNotificationPlanner(horizonDays: 40, calendar: calendar)
        let rule = insertRule(
            "Rent",
            startingOn: day(2025, 1, 15),
            createdAt: day(2025, 4, 16),
            in: context
        )
        try context.save()

        let requests = planner.requests(for: [rule], currency: euro, now: now)

        #expect(requests.map(\.occurrenceDate) == [day(2025, 5, 15)])
    }

    @Test("A settled occurrence is left out and the next one is kept")
    func leavesOutSettledOccurrence() throws {
        let context = try makeContext()
        let planner = RecurringNotificationPlanner(horizonDays: 40, calendar: calendar)
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        try context.save()

        try service.confirm(occurrence(of: rule, on: day(2025, 4, 15), in: april), in: context)
        let requests = planner.requests(for: [rule], currency: euro, now: now)

        #expect(requests.map(\.occurrenceDate) == [day(2025, 5, 15)])
    }

    @Test("A skipped occurrence is left out and the next one is kept")
    func leavesOutSkippedOccurrence() throws {
        let context = try makeContext()
        let planner = RecurringNotificationPlanner(horizonDays: 40, calendar: calendar)
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        try context.save()

        try service.skip(occurrence(of: rule, on: day(2025, 4, 15), in: april), in: context)
        let requests = planner.requests(for: [rule], currency: euro, now: now)

        #expect(requests.map(\.occurrenceDate) == [day(2025, 5, 15)])
    }

    @Test("Moving the payment day doesn't bring back a period already settled")
    func settledPeriodStaysSettledAfterMovingPaymentDay() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 1, 2), in: context)
        try context.save()
        try service.confirm(occurrence(of: rule, on: day(2025, 4, 2), in: april), in: context)

        rule.startDate = day(2025, 1, 20)
        try context.save()
        let requests = planner.requests(for: [rule], currency: euro, now: now)

        #expect(requests.isEmpty)
    }

    @Test("Nothing is planned after the rule's end date")
    func stopsAfterEndDate() throws {
        let context = try makeContext()
        let rule = insertRule(
            "Gym",
            frequency: .weekly,
            startingOn: day(2025, 4, 1),
            endingOn: day(2025, 4, 22),
            repartition: [.wants: -29_00],
            in: context
        )
        try context.save()

        let requests = planner.requests(for: [rule], currency: euro, now: now)

        #expect(requests.map(\.occurrenceDate) == [day(2025, 4, 15), day(2025, 4, 22)])
    }

    @Test("An automatic rule is announced as added automatically")
    func automaticRuleIsAddedAutomatically() throws {
        let context = try makeContext()
        let rule = insertRule("Netflix", startingOn: day(2025, 1, 15), repartition: [.wants: -13_99], automatic: true, in: context)
        try context.save()

        let request = try #require(planner.requests(for: [rule], currency: euro, now: now).first)

        #expect(request.kind == .addedAutomatically)
        #expect(request.body == String(localized: "Added automatically."))
    }

    @Test("An income uses the received copy")
    func incomeUsesReceivedCopy() throws {
        let context = try makeContext()
        let rule = insertRule("Salary", startingOn: day(2025, 1, 15), repartition: [.needs: 1500_00, .wants: 500_00], in: context)
        try context.save()

        let request = try #require(planner.requests(for: [rule], currency: euro, now: now).first)

        #expect(request.kind == .due)
        #expect(request.body == String(localized: "Expected today. Open Trente to mark it as received."))
        #expect(request.title == WalletNotificationService.title(amountCents: 2000_00, currency: euro, title: "Salary"))
    }

    @Test("The title shows the absolute amount and the rule's title")
    func titleUsesAbsoluteAmountAndTitle() throws {
        let context = try makeContext()
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        try context.save()

        let request = try #require(planner.requests(for: [rule], currency: euro, now: now).first)

        #expect(request.title == WalletNotificationService.title(amountCents: 800_00, currency: euro, title: "Rent"))
        #expect(request.title.hasSuffix(" - Rent"))
        #expect(!request.title.contains("-800"))
    }

    @Test("Only the soonest requests are kept up to the limit")
    func capsAtLimitSoonestFirst() throws {
        let context = try makeContext()
        let planner = RecurringNotificationPlanner(limit: 3, calendar: calendar)
        let gym = insertRule("Gym", frequency: .weekly, startingOn: day(2025, 4, 1), repartition: [.wants: -29_00], in: context)
        let lunch = insertRule("Lunch", frequency: .weekly, startingOn: day(2025, 4, 3), repartition: [.wants: -12_00], in: context)
        try context.save()

        let requests = planner.requests(for: [gym, lunch], currency: euro, now: now)

        #expect(requests.map(\.occurrenceDate) == [day(2025, 4, 10), day(2025, 4, 15), day(2025, 4, 17)])
        #expect(requests.map(\.ruleID) == [lunch.id, gym.id, lunch.id])
    }

    @Test("Dates beyond the horizon are not planned")
    func ignoresDatesBeyondHorizon() throws {
        let context = try makeContext()
        let planner = RecurringNotificationPlanner(horizonDays: 10, calendar: calendar)
        let rule = insertRule("Rent", startingOn: day(2025, 1, 30), in: context)
        try context.save()

        let requests = planner.requests(for: [rule], currency: euro, now: now)

        #expect(requests.isEmpty)
    }

    @Test("Occurrences are planned even when their month doesn't exist yet")
    func doesNotNeedAMonth() throws {
        let context = try makeContext()
        let planner = RecurringNotificationPlanner(horizonDays: 40, calendar: calendar)
        insertMonth(year: 2025, month: 4, in: context)
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        try context.save()

        let requests = planner.requests(for: [rule], currency: euro, now: now)

        #expect(requests.map(\.occurrenceDate) == [day(2025, 4, 15), day(2025, 5, 15)])
    }

    @Test("The identifier is made of the rule's permanent id and the occurrence's day")
    func identifierUsesRuleIDAndDay() throws {
        let context = try makeContext()
        let rule = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        let request = try #require(planner.requests(for: [rule], currency: euro, now: now).first)

        let identifier = RecurringNotificationScheduler.identifier(for: request, calendar: calendar)

        #expect(identifier == "recurring.\(rule.id.uuidString).2025-04-15")
    }

    @Test("Buttons are offered only for a manual occurrence inside an existing month")
    func buttonsNeedAManualOccurrenceInAMonth() throws {
        let context = try makeContext()
        let planner = RecurringNotificationPlanner(horizonDays: 40, calendar: calendar)
        let rent = insertRule("Rent", startingOn: day(2025, 1, 15), in: context)
        let salary = insertRule("Salary", startingOn: day(2025, 1, 12), repartition: [.needs: 1000_00], automatic: true, in: context)
        let april = DateInterval(start: day(2025, 4, 1), end: day(2025, 5, 1))

        let requests = planner.requests(for: [rent, salary], currency: euro, now: now, monthIntervals: [april])

        let confirmable = requests.map { request in "\(request.ruleID == rent.id ? "rent" : "salary") \(request.canBeConfirmed)" }
        #expect(confirmable == ["salary false", "rent true", "salary false", "rent false"])
    }

    @Test("An income occurrence is flagged as income")
    func incomeIsFlagged() throws {
        let context = try makeContext()
        let rule = insertRule("Salary", startingOn: day(2025, 1, 15), repartition: [.needs: 1000_00], in: context)

        let request = try #require(planner.requests(for: [rule], currency: euro, now: now).first)

        #expect(request.isIncome)
    }
}
