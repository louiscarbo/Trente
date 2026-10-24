//
//  RecurringNotificationResponderTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Trente

@MainActor
@Suite(.serialized)
struct RecurringNotificationResponderTests {
    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func insertRule(
        _ title: String,
        repartition: [BudgetCategory: Int] = [.needs: -800_00],
        in context: ModelContext
    ) -> RecurringTransactionRule {
        let rule = RecurringTransactionRule(
            title: title,
            frequency: .monthly,
            startDate: day(2026, 1, 15),
            repartition: repartition,
            createdAt: day(2026, 1, 1)
        )
        context.insert(rule)
        return rule
    }

    @Test("The payload survives a round trip through userInfo")
    func payloadRoundTrip() {
        let payload = RecurringNotificationPayload(ruleID: UUID(), occurrenceDate: day(2026, 10, 15))

        #expect(RecurringNotificationPayload(userInfo: payload.userInfo) == payload)
    }

    @Test("A notification without a recurring payload is not one of ours")
    func foreignUserInfo() {
        #expect(RecurringNotificationPayload(userInfo: ["pendingTransactionID": UUID().uuidString]) == nil)
    }

    @Test("Mark as Paid records the occurrence in its month")
    func markAsPaidRecordsTransaction() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        let rule = insertRule("Rent", in: context)
        try context.save()
        let payload = RecurringNotificationPayload(ruleID: rule.id, occurrenceDate: day(2026, 10, 15))

        let handled = try RecurringNotificationResponder.handle(.markAsPaid, payload: payload, in: context)

        #expect(handled)
        let group = try #require(try context.fetch(FetchDescriptor<TransactionGroup>()).first)
        #expect(group.month.id == october.id)
        #expect(group.recurringRule?.id == rule.id)
        #expect(group.recurringOccurrenceDate == day(2026, 10, 15))
        #expect(group.totalAmountCents == -800_00)
    }

    @Test("Marking twice records the occurrence once")
    func markAsPaidTwice() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let rule = insertRule("Rent", in: context)
        try context.save()
        let payload = RecurringNotificationPayload(ruleID: rule.id, occurrenceDate: day(2026, 10, 15))

        try RecurringNotificationResponder.handle(.markAsPaid, payload: payload, in: context)
        try RecurringNotificationResponder.handle(.markAsPaid, payload: payload, in: context)

        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).count == 1)
    }

    @Test("Skip marks the occurrence as skipped without a transaction")
    func skipMarksOccurrence() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let rule = insertRule("Rent", in: context)
        try context.save()
        let payload = RecurringNotificationPayload(ruleID: rule.id, occurrenceDate: day(2026, 10, 15))

        let handled = try RecurringNotificationResponder.handle(.skip, payload: payload, in: context)

        #expect(handled)
        #expect(rule.isSkipped(on: day(2026, 10, 15)))
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).isEmpty)
    }

    @Test("Mark as Paid does nothing when the month doesn't exist yet")
    func markAsPaidWithoutMonth() throws {
        let context = try makeContext()
        let rule = insertRule("Rent", in: context)
        try context.save()
        let payload = RecurringNotificationPayload(ruleID: rule.id, occurrenceDate: day(2026, 10, 15))

        let handled = try RecurringNotificationResponder.handle(.markAsPaid, payload: payload, in: context)

        #expect(!handled)
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).isEmpty)
    }

    @Test("A date that isn't one of the rule's occurrences is ignored")
    func dateOutsideScheduleIsIgnored() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let rule = insertRule("Rent", in: context)
        try context.save()
        let payload = RecurringNotificationPayload(ruleID: rule.id, occurrenceDate: day(2026, 10, 16))

        let handled = try RecurringNotificationResponder.handle(.markAsPaid, payload: payload, in: context)

        #expect(!handled)
        #expect(try context.fetch(FetchDescriptor<TransactionGroup>()).isEmpty)
    }

    @Test("A deleted rule is ignored")
    func deletedRuleIsIgnored() throws {
        let context = try makeContext()
        insertMonth(year: 2026, month: 10, in: context)
        let payload = RecurringNotificationPayload(ruleID: UUID(), occurrenceDate: day(2026, 10, 15))

        let handled = try RecurringNotificationResponder.handle(.markAsPaid, payload: payload, in: context)

        #expect(!handled)
    }
}

@MainActor
@Suite(.serialized)
struct DeliveredRecurringNotificationTests {
    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeRule(_ title: String, startingOn startDate: Date, amountCents: Int) -> RecurringTransactionRule {
        RecurringTransactionRule(
            title: title,
            frequency: .monthly,
            startDate: startDate,
            repartition: [.needs: amountCents],
            createdAt: day(2026, 1, 1)
        )
    }

    @Test("Delivered reminders are cleared once paid, skipped or deleted, and kept while pending")
    func clearsOnlySettledReminders() throws {
        let context = try makeContext()
        let october = insertMonth(year: 2026, month: 10, in: context)
        let rent = makeRule("Rent", startingOn: day(2026, 1, 15), amountCents: -800_00)
        let gym = makeRule("Gym", startingOn: day(2026, 1, 20), amountCents: -30_00)
        let phone = makeRule("Phone", startingOn: day(2026, 1, 5), amountCents: -20_00)
        [rent, gym, phone].forEach { rule in context.insert(rule) }
        try context.save()
        try RecurringTransactionService.shared.confirm(
            RecurringTransactionOccurrence(rule: rent, date: day(2026, 10, 15), month: october),
            in: context
        )
        try RecurringTransactionService.shared.skip(
            RecurringTransactionOccurrence(rule: gym, date: day(2026, 10, 20), month: october),
            in: context
        )
        let delivered = [
            (identifier: "rent", payload: RecurringNotificationPayload(ruleID: rent.id, occurrenceDate: day(2026, 10, 15))),
            (identifier: "gym", payload: RecurringNotificationPayload(ruleID: gym.id, occurrenceDate: day(2026, 10, 20))),
            (identifier: "phone", payload: RecurringNotificationPayload(ruleID: phone.id, occurrenceDate: day(2026, 10, 5))),
            (identifier: "deleted", payload: RecurringNotificationPayload(ruleID: UUID(), occurrenceDate: day(2026, 10, 5)))
        ]

        let cleared = RecurringNotificationPlanner().identifiersToClear(delivered: delivered, rules: [rent, gym, phone])

        #expect(cleared == ["rent", "gym", "deleted"])
    }
}
