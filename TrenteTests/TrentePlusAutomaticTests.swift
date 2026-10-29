//
//  TrentePlusAutomaticTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Testing
import SwiftData
@testable import Trente
import Foundation
import Synchronization

@Suite(.serialized)
struct TrentePlusAutomaticTests {
    private let calendar = Calendar.current
    private let service = RecurringTransactionService.shared

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func insertAutomaticRent(startingOn startDate: Date, in context: ModelContext) -> RecurringTransactionRule {
        let rule = RecurringTransactionRule(
            title: "Rent",
            frequency: .monthly,
            startDate: startDate,
            autoConfirm: true,
            repartition: [.needs: -800_00],
            createdAt: startDate
        )
        context.insert(rule)
        return rule
    }

    private func confirmedDates(in context: ModelContext) throws -> [Date] {
        try context.fetch(FetchDescriptor<TransactionGroup>()).compactMap(\.recurringOccurrenceDate).sorted()
    }

    @Test("Without Trente+, a due automatic transaction waits for confirmation and the rule stays automatic")
    func lapsedRuleAsksForConfirmation() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertAutomaticRent(startingOn: day(2025, 4, 2), in: context)
        try context.save()

        let confirmedCount = try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: false)

        #expect(confirmedCount == 0)
        #expect(april.transactionGroups.isEmpty)
        #expect(service.pendingOccurrences(of: [rule], in: april).map(\.date) == [day(2025, 4, 2)])
        #expect(rule.autoConfirm)
    }

    @Test("Subscribing again adds the next ones automatically, but leaves the ones due without Trente+ to confirm")
    func resubscribingIsNotRetroactive() throws {
        let context = try makeContext()
        let months = (1...4).map { insertMonth(year: 2025, month: $0, in: context) }
        let rule = insertAutomaticRent(startingOn: day(2025, 1, 2), in: context)
        try context.save()

        try service.confirmDueOccurrences(in: context, now: day(2025, 2, 10), isAutomaticUnlocked: true)
        try service.confirmDueOccurrences(in: context, now: day(2025, 3, 10), isAutomaticUnlocked: false)
        try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: true)

        #expect(try confirmedDates(in: context) == [day(2025, 1, 2), day(2025, 2, 2), day(2025, 4, 2)])
        #expect(service.pendingOccurrences(of: [rule], in: months[2]).map(\.date) == [day(2025, 3, 2)])
    }

    @Test("Without Trente+, a transaction confirmed by hand is not added a second time after subscribing again")
    func manualConfirmWhileLapsedIsKept() throws {
        let context = try makeContext()
        let april = insertMonth(year: 2025, month: 4, in: context)
        let rule = insertAutomaticRent(startingOn: day(2025, 4, 2), in: context)
        try context.save()

        try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: false)
        try service.confirm(try #require(service.pendingOccurrences(of: [rule], in: april).first), in: context)
        let confirmedCount = try service.confirmDueOccurrences(in: context, now: day(2025, 4, 11), isAutomaticUnlocked: true)

        #expect(confirmedCount == 0)
        #expect(april.transactionGroups.count == 1)
    }

    @Test("Without Trente+, catching up again with nothing new doesn't save")
    func lapsedCatchUpSettles() throws {
        let context = try makeContext()
        insertMonth(year: 2025, month: 4, in: context)
        _ = insertAutomaticRent(startingOn: day(2025, 4, 2), in: context)
        try context.save()
        try service.confirmDueOccurrences(in: context, now: day(2025, 4, 10), isAutomaticUnlocked: false)

        let saveCount = Mutex(0)
        let observer = NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: context, queue: nil) { _ in
            saveCount.withLock { $0 += 1 }
        }
        try service.confirmDueOccurrences(in: context, now: day(2025, 4, 11), isAutomaticUnlocked: false)
        NotificationCenter.default.removeObserver(observer)

        #expect(saveCount.withLock { $0 } == 0)
    }

    @MainActor
    @Test("Without Trente+, catching up still starts the new months")
    func lapsedCatchUpStartsMonths() throws {
        let context = try makeContext()
        insertMonth(year: 2025, month: 3, in: context)
        _ = insertAutomaticRent(startingOn: day(2025, 3, 2), in: context)
        try context.save()

        try CatchUpService.shared.catchUp(in: context, now: day(2025, 4, 10), isTrentePlusSubscribed: false)

        let months = try context.fetch(FetchDescriptor<Month>(sortBy: [SortDescriptor(\.startDate)]))
        #expect(months.map(\.startDate) == [day(2025, 3, 1), day(2025, 4, 1)])
        #expect(try confirmedDates(in: context).isEmpty)
    }

    @Test("Without Trente+, an automatic rule's reminder asks for confirmation")
    func lapsedRuleIsAnnouncedAsDue() throws {
        let context = try makeContext()
        let rule = insertAutomaticRent(startingOn: day(2025, 4, 15), in: context)
        try context.save()
        let planner = RecurringNotificationPlanner(automaticUnlockedUntil: .distantPast)

        let request = try #require(planner.requests(for: [rule], currency: Currencies.currency(for: "EUR")!, now: day(2025, 4, 10)).first)

        #expect(request.kind == .due)
    }

    @Test("When Trente+ won't renew, reminders after it ends ask for confirmation")
    func endingSubscriptionAnnouncesLaterOnesAsDue() throws {
        let context = try makeContext()
        let rule = insertAutomaticRent(startingOn: day(2025, 4, 15), in: context)
        try context.save()
        let planner = RecurringNotificationPlanner(automaticUnlockedUntil: day(2025, 5, 1), horizonDays: 60)

        let requests = planner.requests(for: [rule], currency: Currencies.currency(for: "EUR")!, now: day(2025, 4, 10))

        #expect(requests.map(\.occurrenceDate) == [day(2025, 4, 15), day(2025, 5, 15)])
        #expect(requests.map(\.kind) == [.addedAutomatically, .due])
    }

    @Test("The Trente+ status is remembered for the widget, and defaults to not subscribed")
    func entitlementCache() throws {
        let defaults = try #require(UserDefaults(suiteName: "TrentePlusAutomaticTests.\(UUID().uuidString)"))

        #expect(!TrentePlusEntitlement.cached(in: defaults))
        TrentePlusEntitlement.cache(true, in: defaults)
        #expect(TrentePlusEntitlement.cached(in: defaults))
        TrentePlusEntitlement.cache(false, in: defaults)
        #expect(!TrentePlusEntitlement.cached(in: defaults))
    }
}
