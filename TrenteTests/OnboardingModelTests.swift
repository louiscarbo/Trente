//
//  OnboardingModelTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Trente

@MainActor
struct OnboardingModelTests {

    @Test("The default draft uses the locale's currency, today and an empty budget")
    func defaultDraft() {
        let today = Date.now
        let model = OnboardingModel(steps: OnboardingStep.allCases, locale: Locale(identifier: "en_US"), startDate: today)

        #expect(model.draft.currency.isoCode == "USD")
        #expect(model.draft.startDate == today)
        #expect(model.draft.idealBudgetCents == 0)
        #expect(model.draft.idealRepartition.values.allSatisfy { $0 == 0 })
    }

    @Test("The default currency falls back to euros when the locale's currency is unsupported")
    func defaultCurrencyFallback() {
        let currency = OnboardingModel.defaultCurrency(for: Locale(identifier: "ar_EG"))

        #expect(currency.isoCode == "EUR")
    }

    @Test("Moving forward and back follows the step list and stops at both ends")
    func navigation() {
        let model = OnboardingModel(steps: [.welcome, .budget, .allSet])

        #expect(model.currentStep == .welcome)
        #expect(!model.canGoBack)

        model.goBack()
        #expect(model.currentStep == .welcome)

        model.goForward()
        #expect(model.currentStep == .budget)
        #expect(model.direction == .forward)

        model.goForward()
        #expect(model.currentStep == .allSet)
        #expect(model.isLastStep)

        model.goForward()
        #expect(model.currentStep == .allSet)

        model.goBack()
        #expect(model.currentStep == .budget)
        #expect(model.direction == .backward)
    }

    @Test(
        "The 50/30/20 pre-fill rounds needs and wants down to whole units and gives savings the rest",
        arguments: [
            (2000_00, 1000_00, 600_00, 400_00),
            (1234_00, 617_00, 370_00, 247_00),
            (1234_56, 617_00, 370_00, 247_56),
            (0, 0, 0, 0)
        ]
    )
    func suggestedRepartition(budgetCents: Int, needs: Int, wants: Int, savings: Int) {
        let repartition = OnboardingModel.suggestedRepartition(for: budgetCents)

        #expect(repartition[.needs] == needs)
        #expect(repartition[.wants] == wants)
        #expect(repartition[.savingsAndDebts] == savings)
        #expect(repartition.values.reduce(0, +) == budgetCents)
    }

    @Test("Changing the budget re-applies 50/30/20 while the split is untouched")
    func budgetChangeKeepsSuggestedSplit() {
        let model = OnboardingModel(steps: OnboardingStep.allCases)

        model.budgetCents = 2000_00
        model.budgetCents = 1500_00

        #expect(model.draft.idealRepartition == OnboardingModel.suggestedRepartition(for: 1500_00))
    }

    @Test("A raised budget keeps a split the user adjusted")
    func raisedBudgetKeepsAdjustedSplit() {
        let model = OnboardingModel(steps: OnboardingStep.allCases)
        model.budgetCents = 2000_00
        let adjusted: [BudgetCategory: Int] = [.needs: 1200_00, .wants: 400_00, .savingsAndDebts: 400_00]
        model.draft.idealRepartition = adjusted

        model.budgetCents = 2500_00

        #expect(model.draft.idealRepartition == adjusted)
    }

    @Test("A lowered budget replaces an adjusted split that no longer fits")
    func loweredBudgetResetsAdjustedSplit() {
        let model = OnboardingModel(steps: OnboardingStep.allCases)
        model.budgetCents = 2000_00
        model.draft.idealRepartition = [.needs: 1200_00, .wants: 400_00, .savingsAndDebts: 400_00]

        model.budgetCents = 1000_00

        #expect(model.draft.idealRepartition == OnboardingModel.suggestedRepartition(for: 1000_00))
    }

    @Test("Saving twice creates one month and updates it the second time")
    func savingTwiceUpdatesTheSameMonth() throws {
        let context = try makeContext()
        let model = OnboardingModel(steps: OnboardingStep.allCases)
        model.budgetCents = 2000_00

        try model.saveMonth(in: context)
        model.budgetCents = 2500_00
        try model.saveMonth(in: context)

        let months = try context.fetch(FetchDescriptor<Month>())
        #expect(months.count == 1)
        #expect(months.first?.idealBudgetCents == 2500_00)
        #expect(months.first?.idealRepartition == OnboardingModel.suggestedRepartition(for: 2500_00))
    }

    @Test("On first launch, a second window updates the month the first window saved")
    func firstLaunchReusesMonthSavedByAnotherWindow() throws {
        let context = try makeContext()
        let firstWindow = OnboardingModel(steps: OnboardingStep.allCases)
        let secondWindow = OnboardingModel(steps: OnboardingStep.allCases)
        firstWindow.budgetCents = 2000_00
        secondWindow.budgetCents = 3000_00

        try firstWindow.saveMonth(in: context, reusingExistingMonth: true)
        try secondWindow.saveMonth(in: context, reusingExistingMonth: true)

        let months = try context.fetch(FetchDescriptor<Month>())
        #expect(months.count == 1)
        #expect(months.first?.idealBudgetCents == 3000_00)
    }

    @Test("A replayed onboarding creates its own month instead of changing an existing one")
    func replayKeepsExistingMonth() throws {
        let context = try makeContext()
        let firstLaunch = OnboardingModel(steps: OnboardingStep.allCases)
        firstLaunch.budgetCents = 2000_00
        try firstLaunch.saveMonth(in: context, reusingExistingMonth: true)

        let replay = OnboardingModel(steps: OnboardingStep.allCases)
        replay.budgetCents = 3000_00
        try replay.saveMonth(in: context)

        let budgets = try context.fetch(FetchDescriptor<Month>()).map(\.idealBudgetCents)
        #expect(budgets.sorted() == [2000_00, 3000_00])
    }

    @Test("Adding the income logs this month's income and repeats it from next month, not automatically")
    func addingIncome() throws {
        let context = try makeContext()
        let today = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 14)))
        let model = OnboardingModel(steps: OnboardingStep.allCases, startDate: today)
        model.budgetCents = 2000_00
        try model.saveMonth(in: context)

        try model.addIncome(in: context, now: today)

        let month = try #require(model.savedMonth)
        let income = try #require(month.transactionGroups.first)
        let rule = try #require(income.recurringRule)
        #expect(month.transactionGroups.count == 1)
        #expect(income.type == .income)
        #expect(income.addedDate == Calendar.current.startOfDay(for: today))
        #expect(month.remainingAmount == 2000)
        #expect(rule.frequency == .monthly)
        #expect(!rule.autoConfirm)
        #expect(rule.repartition == OnboardingModel.suggestedRepartition(for: 2000_00))
        #expect(rule.startDate == month.dateInterval.end)
        #expect(rule.pendingOccurrences(in: month).isEmpty)
    }

    @Test("The income is added once")
    func addingIncomeTwiceAddsItOnce() throws {
        let context = try makeContext()
        let model = OnboardingModel(steps: OnboardingStep.allCases)
        model.budgetCents = 2000_00
        try model.saveMonth(in: context)

        try model.addIncome(in: context)
        try model.addIncome(in: context)

        #expect(try context.fetchCount(FetchDescriptor<RecurringTransactionRule>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<TransactionGroup>()) == 1)
    }

    @Test(
        "The income repeats from the first month start that isn't in the past",
        arguments: [
            ((2026, 10, 29), (2026, 10, 29), (2026, 11, 29)),
            ((2026, 10, 1), (2026, 10, 29), (2026, 11, 1)),
            ((2026, 8, 15), (2026, 10, 29), (2026, 11, 15)),
            ((2026, 9, 29), (2026, 10, 29), (2026, 10, 29)),
            ((2026, 11, 5), (2026, 10, 29), (2026, 12, 5)),
            ((2027, 1, 31), (2027, 1, 31), (2027, 2, 28))
        ]
    )
    func incomeStartDate(monthStart: (Int, Int, Int), today: (Int, Int, Int), expected: (Int, Int, Int)) throws {
        let calendar = Calendar.current
        func date(_ components: (Int, Int, Int)) throws -> Date {
            try #require(calendar.date(from: DateComponents(year: components.0, month: components.1, day: components.2)))
        }

        let startDate = OnboardingModel.incomeStartDate(
            afterMonthStartingOn: try date(monthStart),
            today: try date(today)
        )

        #expect(startDate == (try date(expected)))
    }

    @Test(
        "The gate shows onboarding only without a completed flag and without months, unless forced",
        arguments: [
            (false, 0, false, true),
            (true, 0, false, false),
            (false, 1, false, false),
            (true, 3, false, false),
            (true, 3, true, true)
        ]
    )
    func gate(hasCompletedOnboarding: Bool, monthCount: Int, isForced: Bool, expected: Bool) {
        let shouldShow = OnboardingGate.shouldShow(
            hasCompletedOnboarding: hasCompletedOnboarding,
            monthCount: monthCount,
            isForced: isForced
        )

        #expect(shouldShow == expected)
    }
}
