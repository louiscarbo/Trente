//
//  TransactionServiceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 14/05/2026.
//

import Testing
import SwiftData
@testable import Trente
import Foundation

@Suite(.serialized)
struct TransactionServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Month.self, configurations: config)
        return ModelContext(container)
    }

    private func makeMonth(in context: ModelContext) -> Month {
        let eur = Currencies.currency(for: "EUR")!
        let month = Month(
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 1))!,
            currency: eur,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )
        context.insert(month)
        return month
    }

    @Test("Deleting a plain group removes it and its entries")
    func deletePlainGroup() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)

        let group = TransactionGroup(title: "Coffee", type: .expense, month: month, note: nil, imageAttachmentData: nil)
        context.insert(group)
        let entry = TransactionEntry(amountCents: -5_00, category: .wants, group: group)
        context.insert(entry)
        group.entries = [entry]
        month.transactionGroups = [group]
        try context.save()

        TransactionService.shared.delete(group: group, in: context)
        try context.save()

        let groups = try context.fetch(FetchDescriptor<TransactionGroup>())
        let entries = try context.fetch(FetchDescriptor<TransactionEntry>())
        #expect(groups.isEmpty)
        #expect(entries.isEmpty)
    }

    @Test("Confirming a recurring instance creates a linked group in the month")
    func confirmRecurringInstance_createsLinkedGroup() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)

        let rule = RecurringTransactionRule(
            title: "Salary",
            frequency: .monthly,
            startDate: month.startDate,
            repartition: [.needs: 1500_00, .wants: 500_00]
        )
        context.insert(rule)

        let instance = RecurringTransactionInstance(date: month.startDate, rule: rule, month: month, confirmed: false)
        context.insert(instance)
        month.recurringTransactionInstances = [instance]
        rule.instances = [instance]
        try context.save()

        try RecurringTransactionService.shared.confirm(instance: instance, in: context)

        #expect(instance.confirmed)
        #expect(month.transactionGroups.count == 1, "Confirmed group must appear in the month")
        let group = try #require(month.transactionGroups.first)
        #expect(group.type == .income)
        #expect(group.entries.count == 2)
        #expect(group.totalAmountCents == 2000_00)
        #expect(instance.transactionGroup?.id == group.id)
    }

    @Test("Confirming an already-confirmed instance is a no-op")
    func confirmTwice_doesNotDuplicate() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)

        let rule = RecurringTransactionRule(
            title: "Salary",
            frequency: .monthly,
            startDate: month.startDate,
            repartition: [.needs: 1000_00]
        )
        context.insert(rule)

        let instance = RecurringTransactionInstance(date: month.startDate, rule: rule, month: month, confirmed: false)
        context.insert(instance)
        month.recurringTransactionInstances = [instance]
        rule.instances = [instance]
        try context.save()

        try RecurringTransactionService.shared.confirm(instance: instance, in: context)
        try RecurringTransactionService.shared.confirm(instance: instance, in: context)

        #expect(month.transactionGroups.count == 1, "Second confirm must not create another group")
    }

    @Test("Deleting a confirmed recurring group also removes the linked instance")
    func deleteConfirmedRecurringGroup_deletesLinkedInstance() throws {
        let context = try makeContext()
        let month = makeMonth(in: context)

        let rule = RecurringTransactionRule(
            title: "Rent",
            frequency: .monthly,
            startDate: month.startDate,
            repartition: [.needs: -800_00]
        )
        context.insert(rule)

        let group = TransactionGroup(title: "Rent", type: .expense, month: month, note: nil, imageAttachmentData: nil)
        context.insert(group)

        let instance = RecurringTransactionInstance(date: month.startDate, rule: rule, month: month, confirmed: false)
        instance.transactionGroup = group
        context.insert(instance)

        month.transactionGroups = [group]
        month.recurringTransactionInstances = [instance]
        try context.save()

        TransactionService.shared.delete(group: group, in: context)
        try context.save()

        let remainingInstances = try context.fetch(FetchDescriptor<RecurringTransactionInstance>())
        #expect(remainingInstances.isEmpty)

        let remainingRules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        #expect(remainingRules.count == 1, "The rule itself should not be deleted")
    }

    @Test("Deleting one confirmed recurring group does not affect other months' instances")
    func deleteConfirmedRecurringGroup_doesNotAffectOtherInstances() throws {
        let context = try makeContext()
        let calendar = Calendar(identifier: .gregorian)
        let eur = Currencies.currency(for: "EUR")!

        let month1 = Month(
            startDate: calendar.date(from: DateComponents(year: 2025, month: 4, day: 1))!,
            currency: eur,
            idealBudgetCents: 2000_00,
            idealRepartition: [:]
        )
        let month2 = Month(
            startDate: calendar.date(from: DateComponents(year: 2025, month: 5, day: 1))!,
            currency: eur,
            idealBudgetCents: 2000_00,
            idealRepartition: [:]
        )
        context.insert(month1)
        context.insert(month2)

        let rule = RecurringTransactionRule(
            title: "Rent",
            frequency: .monthly,
            startDate: month1.startDate,
            repartition: [.needs: -800_00]
        )
        context.insert(rule)

        let group = TransactionGroup(title: "Rent", type: .expense, month: month1, note: nil, imageAttachmentData: nil)
        context.insert(group)
        let instance1 = RecurringTransactionInstance(date: month1.startDate, rule: rule, month: month1, confirmed: false)
        instance1.transactionGroup = group
        context.insert(instance1)

        let instance2 = RecurringTransactionInstance(date: month2.startDate, rule: rule, month: month2, confirmed: false)
        context.insert(instance2)

        month1.transactionGroups = [group]
        month1.recurringTransactionInstances = [instance1]
        month2.recurringTransactionInstances = [instance2]
        try context.save()

        TransactionService.shared.delete(group: group, in: context)
        try context.save()

        let remainingInstances = try context.fetch(FetchDescriptor<RecurringTransactionInstance>())
        #expect(remainingInstances.count == 1, "Only instance1 should be deleted; instance2 must survive")
        #expect(remainingInstances.first?.month.startDate == month2.startDate)

        let remainingRules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        #expect(remainingRules.count == 1)
    }
}
