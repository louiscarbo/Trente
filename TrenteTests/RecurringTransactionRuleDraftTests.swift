//
//  RecurringTransactionRuleDraftTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Testing
@testable import Trente
import Foundation

struct RecurringTransactionRuleDraftTests {
    private let calendar = Calendar.current

    private func daysFromToday(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: .now))!
    }

    private func makeRule(
        frequency: RecurrenceFrequency,
        startDate: Date,
        endDate: Date? = nil
    ) -> RecurringTransactionRule {
        RecurringTransactionRule(
            title: "Rent",
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            repartition: [.needs: -800_00],
            createdAt: startDate
        )
    }

    @Test("Changing the frequency of a running rule restarts it on its next date")
    func frequencyChangeRestartsOnNextDate() {
        let rule = makeRule(frequency: .weekly, startDate: daysFromToday(-13))
        var draft = RecurringTransactionRuleDraft(from: rule)

        draft.setFrequency(.monthly)

        #expect(draft.startDate == daysFromToday(1))
        #expect(draft.validate().isEmpty)
    }

    @Test("Changing the frequency of a rule not started yet keeps its start date")
    func frequencyChangeKeepsFutureStart() {
        let startDate = daysFromToday(10)
        var draft = RecurringTransactionRuleDraft(from: makeRule(frequency: .monthly, startDate: startDate))

        draft.setFrequency(.weekly)

        #expect(draft.startDate == startDate)
    }

    @Test("A rule stopped before it started can still be edited")
    func stoppedBeforeStartCanBeEdited() {
        let rule = makeRule(frequency: .monthly, startDate: daysFromToday(10), endDate: daysFromToday(0))
        var draft = RecurringTransactionRuleDraft(from: rule)

        draft.title = "Flat rent"

        #expect(draft.validate().isEmpty)
    }

    @Test("Changing the category of an expense moves its whole amount")
    func categoryChangeMovesExpenseAmount() {
        var draft = RecurringTransactionRuleDraft(from: makeRule(frequency: .monthly, startDate: daysFromToday(10)))

        draft.expenseCategory = .wants

        #expect(draft.expenseCategory == .wants)
        #expect(draft.repartition == [.wants: -800_00])
        #expect(draft.validate().isEmpty)
    }

    @Test("Clearing the category of an expense keeps the current one")
    func clearingCategoryKeepsRepartition() {
        var draft = RecurringTransactionRuleDraft(from: makeRule(frequency: .monthly, startDate: daysFromToday(10)))

        draft.expenseCategory = nil

        #expect(draft.repartition == [.needs: -800_00])
    }

    @Test("An expense amount is always stored as a negative amount in its category")
    func expenseAmountIsStoredNegative() {
        var draft = RecurringTransactionRuleDraft(from: makeRule(frequency: .monthly, startDate: daysFromToday(10)))

        draft.expenseAmountCents = 950_00

        #expect(draft.expenseAmountCents == -950_00)
        #expect(draft.repartitionTotalCents == -950_00)
        #expect(draft.repartition == [.needs: -950_00])
        #expect(draft.validate().isEmpty)
    }

    @Test("Applying an untouched draft leaves the rule unchanged")
    func untouchedDraftRoundTrips() {
        let rule = makeRule(frequency: .monthly, startDate: daysFromToday(-40), endDate: daysFromToday(200))
        rule.autoConfirm = true

        RecurringTransactionRuleDraft(from: rule).apply(to: rule)

        #expect(rule.title == "Rent")
        #expect(rule.frequency == .monthly)
        #expect(rule.startDate == daysFromToday(-40))
        #expect(rule.endDate == daysFromToday(200))
        #expect(rule.autoConfirm)
        #expect(rule.repartition == [.needs: -800_00])
    }
}
