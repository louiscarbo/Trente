//
//  RecurringTransactionValidationTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 20/05/2026.
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct RecurringTransactionValidationTests {

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Month.self, configurations: config)
        return ModelContext(container)
    }

    private func makeMonth(
        startDate: Date = Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 1))!,
        in context: ModelContext
    ) -> Month {
        let eur = Currencies.currency(for: "EUR")!
        let month = Month(
            startDate: startDate,
            currency: eur,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )
        context.insert(month)
        return month
    }

    private func makeRule(
        title: String = "Rent",
        startDate: Date = Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 1))!,
        autoConfirm: Bool = false,
        repartition: [BudgetCategory: Int] = [.needs: -800_00],
        in context: ModelContext
    ) -> RecurringTransactionRule {
        let rule = RecurringTransactionRule(
            title: title,
            frequency: .monthly,
            startDate: startDate,
            autoConfirm: autoConfirm,
            repartition: repartition
        )
        context.insert(rule)
        return rule
    }

    private func makeInstance(
        date: Date,
        rule: RecurringTransactionRule,
        month: Month,
        in context: ModelContext
    ) -> RecurringTransactionInstance {
        let instance = RecurringTransactionInstance(date: date, rule: rule, month: month, confirmed: false)
        context.insert(instance)
        return instance
    }

    // MARK: - Tests

    @Test("validate creates a linked group with correct entries")
    func validate_createsLinkedGroupWithCorrectEntries() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)
        let rule = makeRule(repartition: [.needs: -800_00], in: context)
        let instance = makeInstance(date: month.startDate, rule: rule, month: month, in: context)
        try context.save()

        try RecurringTransactionService.shared.validate(instance: instance, in: context)

        #expect(instance.transactionGroup != nil)
        #expect(instance.transactionGroup?.entries.count == 1)
        #expect(instance.transactionGroup?.entries.first?.amountCents == -800_00)
        #expect(instance.transactionGroup?.entries.first?.category == .needs)
        #expect(instance.transactionGroup?.title == "Rent")
        #expect(instance.transactionGroup?.type == .expense)
    }

    @Test("validate is idempotent — calling twice keeps exactly one group")
    func validate_isIdempotent() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)
        let rule = makeRule(in: context)
        let instance = makeInstance(date: month.startDate, rule: rule, month: month, in: context)
        try context.save()

        try RecurringTransactionService.shared.validate(instance: instance, in: context)
        try RecurringTransactionService.shared.validate(instance: instance, in: context)

        let groups = try context.fetch(FetchDescriptor<TransactionGroup>())
        #expect(groups.count == 1)
    }

    @Test("autoConfirmDueInstances only confirms autoConfirm=true + past/today instances")
    func autoConfirmDueInstances_onlyConfirmsAutoConfirmTrueAndPastDue() throws {
        let context = try makeContext()
        let calendar = Calendar.current
        let eur = Currencies.currency(for: "EUR")!
        let today = calendar.startOfDay(for: .now)
        let past = today.addingTimeInterval(-86_400 * 2)
        let future = today.addingTimeInterval(86_400 * 2)

        let month = Month(startDate: today, currency: eur, idealBudgetCents: 1000_00, idealRepartition: [:])
        context.insert(month)

        let ruleAutoOn = makeRule(title: "AutoOn", autoConfirm: true, in: context)
        let ruleAutoOff = makeRule(title: "AutoOff", autoConfirm: false, in: context)

        let pastAutoOn = makeInstance(date: past, rule: ruleAutoOn, month: month, in: context)
        let futureAutoOn = makeInstance(date: future, rule: ruleAutoOn, month: month, in: context)
        let pastAutoOff = makeInstance(date: past, rule: ruleAutoOff, month: month, in: context)
        try context.save()

        let count = try RecurringTransactionService.shared.autoConfirmDueInstances(asOf: .now, in: context)

        #expect(count == 1)
        #expect(pastAutoOn.confirmed)
        #expect(!futureAutoOn.confirmed)
        #expect(!pastAutoOff.confirmed)
    }

    @Test("autoConfirmDueInstances is idempotent — second call returns 0")
    func autoConfirmDueInstances_idempotent() throws {
        let context = try makeContext()
        let today = Calendar.current.startOfDay(for: .now)
        let month = makeMonth(in: context)
        let rule = makeRule(autoConfirm: true, in: context)
        _ = makeInstance(date: today, rule: rule, month: month, in: context)
        try context.save()

        _ = try RecurringTransactionService.shared.autoConfirmDueInstances(asOf: .now, in: context)
        let second = try RecurringTransactionService.shared.autoConfirmDueInstances(asOf: .now, in: context)

        #expect(second == 0)
    }

    @Test("autoConfirmDueInstances respects end-of-day cutoff — confirms instances from earlier today")
    func autoConfirmDueInstances_respectsStartOfDayCutoff() throws {
        let context = try makeContext()
        let calendar = Calendar.current
        let todayEarly = calendar.startOfDay(for: .now).addingTimeInterval(3 * 3600)
        let now = calendar.startOfDay(for: .now).addingTimeInterval(9 * 3600)

        let month = makeMonth(in: context)
        let rule = makeRule(autoConfirm: true, in: context)
        let instance = makeInstance(date: todayEarly, rule: rule, month: month, in: context)
        try context.save()

        let count = try RecurringTransactionService.shared.autoConfirmDueInstances(asOf: now, in: context)

        #expect(count == 1)
        #expect(instance.confirmed)
    }

    @Test("validate with overrides uses override repartition")
    func validate_withOverrides_honorsOverrides() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)
        let rule = makeRule(repartition: [.needs: -800_00], in: context)
        let instance = makeInstance(date: month.startDate, rule: rule, month: month, in: context)
        try context.save()

        let overrides = RecurringInstanceOverrides(
            title: "Custom Title",
            repartition: [.wants: -500_00],
            type: .expense
        )
        try RecurringTransactionService.shared.validate(instance: instance, withOverrides: overrides, in: context)

        #expect(instance.transactionGroup?.title == "Custom Title")
        #expect(instance.transactionGroup?.entries.first?.amountCents == -500_00)
        #expect(instance.transactionGroup?.entries.first?.category == .wants)
    }

    @Test("refreshInstances with autoConfirm=true confirms past-due instances")
    func refreshInstances_autoConfirmTrue_catchesUpPastInstances() throws {
        let context = try makeContext()
        let calendar = Calendar.current
        let eur = Currencies.currency(for: "EUR")!
        let past = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!

        let month = Month(startDate: past, currency: eur, idealBudgetCents: 1000_00, idealRepartition: [:])
        context.insert(month)

        let rule = RecurringTransactionRule(
            title: "Auto Rent",
            frequency: .monthly,
            startDate: past,
            autoConfirm: true,
            repartition: [.needs: -800_00]
        )
        context.insert(rule)
        try context.save()

        try RecurringTransactionService.shared.refreshInstances(for: rule, in: context)

        let instances = try context.fetch(FetchDescriptor<RecurringTransactionInstance>())
        let confirmed = instances.filter { $0.confirmed }
        #expect(!confirmed.isEmpty)
    }

    @Test("income rule materializes correctly with multiple positive entries")
    func materialize_incomeRule_createsMultipleEntries() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)
        let rule = makeRule(
            title: "Salary",
            repartition: [.needs: 1000_00, .wants: 300_00, .savingsAndDebts: 200_00],
            in: context
        )
        let instance = makeInstance(date: month.startDate, rule: rule, month: month, in: context)
        try context.save()

        try RecurringTransactionService.shared.validate(instance: instance, in: context)

        #expect(instance.transactionGroup?.type == .income)
        #expect(instance.transactionGroup?.entries.count == 3)
        #expect(instance.transactionGroup?.entries.allSatisfy { $0.amountCents > 0 } == true)
    }
}
