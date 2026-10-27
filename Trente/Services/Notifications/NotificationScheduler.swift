//
//  NotificationScheduler.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import CoreData
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    nonisolated static let systemLimit = 64

    private var container: ModelContainer?
    private var trigger: AppEventTrigger?

    private init() {}

    func start(container: ModelContainer) {
        guard self.container == nil else { return }
        self.container = container
        let events = [
            ModelContext.didSave,
            .NSPersistentStoreRemoteChange,
            .NSCalendarDayChanged,
            UserDefaults.didChangeNotification,
            .appDidBecomeActive,
            .notificationPermissionGranted
        ]
        trigger = AppEventTrigger(events: events, delay: .seconds(1)) {
            await NotificationScheduler.shared.reschedule()
        }
        trigger?.fire()
    }

    func reschedule() async {
        guard let container else { return }
        guard await NotificationPermissionService().status() == .authorized else { return }
        let context = ModelContext(container)
        let reminderTime = ReminderTime.stored()
        let preferences = NotificationPreferences.stored()
        let recurringPlanner = RecurringNotificationPlanner(
            isEnabled: preferences.remindsRecurringTransactions,
            reminderTime: reminderTime
        )
        let newMonthPlanner = NewMonthNotificationPlanner(
            isEnabled: preferences.announcesNewMonths,
            reminderTime: reminderTime
        )
        guard let recurring = try? recurringNotifications(in: context, planner: recurringPlanner),
              let newMonths = try? newMonthNotifications(in: context, planner: newMonthPlanner)
        else { return }

        let notifications = Self.soonest(recurring + newMonths, limit: Self.systemLimit)
        let identifiers = Set(notifications.map(\.identifier))
        let center = UNUserNotificationCenter.current()
        let staleIdentifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { identifier in !identifiers.contains(identifier) }
        center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
        for notification in notifications {
            try? await center.add(notification.request)
        }

        await clearSettledRecurringNotifications(in: context, planner: recurringPlanner, center: center)
    }

    nonisolated static func soonest(_ notifications: [ScheduledNotification], limit: Int) -> [ScheduledNotification] {
        let sorted = notifications.sorted { lhs, rhs in
            if lhs.fireDate != rhs.fireDate {
                return lhs.fireDate < rhs.fireDate
            }
            return lhs.title < rhs.title
        }
        return Array(sorted.prefix(max(0, limit)))
    }

    private func recurringNotifications(
        in context: ModelContext,
        planner: RecurringNotificationPlanner
    ) throws -> [ScheduledNotification] {
        guard let currency = try MonthService.shared.latestMonth(in: context)?.currency else { return [] }
        let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        return planner.requests(for: rules, currency: currency, now: .now)
            .map(\.scheduledNotification)
    }

    private func newMonthNotifications(
        in context: ModelContext,
        planner: NewMonthNotificationPlanner
    ) throws -> [ScheduledNotification] {
        guard let latestMonth = try MonthService.shared.latestMonth(in: context) else { return [] }
        return planner.requests(afterMonthStartingOn: latestMonth.startDate, now: .now)
            .map(\.scheduledNotification)
    }

    private func clearSettledRecurringNotifications(
        in context: ModelContext,
        planner: RecurringNotificationPlanner,
        center: UNUserNotificationCenter
    ) async {
        let delivered = await center.deliveredNotifications().compactMap { notification -> (identifier: String, payload: RecurringNotificationPayload)? in
            let request = notification.request
            guard request.identifier.hasPrefix(RecurringNotificationPlanner.identifierPrefix),
                  let payload = RecurringNotificationPayload(userInfo: request.content.userInfo)
            else { return nil }
            return (request.identifier, payload)
        }
        guard !delivered.isEmpty,
              let rules = try? context.fetch(FetchDescriptor<RecurringTransactionRule>())
        else { return }
        center.removeDeliveredNotifications(withIdentifiers: planner.identifiersToClear(delivered: delivered, rules: rules))
    }
}
