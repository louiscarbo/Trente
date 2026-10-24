//
//  RecurringNotificationScheduler.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
final class RecurringNotificationScheduler {
    static let shared = RecurringNotificationScheduler()
    nonisolated static let threadIdentifier = "recurring"

    private var container: ModelContainer?
    private var trigger: AppEventTrigger?

    private init() {}

    func start(container: ModelContainer) {
        guard self.container == nil else { return }
        self.container = container
        let events = [ModelContext.didSave, .NSCalendarDayChanged, UserDefaults.didChangeNotification, .appDidBecomeActive]
        trigger = AppEventTrigger(events: events, delay: .seconds(1)) {
            await RecurringNotificationScheduler.shared.reschedule()
        }
        trigger?.fire()
    }

    func reschedule() async {
        guard let container else { return }
        guard await NotificationPermissionService().status() == .authorized else { return }
        let planner = RecurringNotificationPlanner(reminderTime: .stored())
        guard let planned = plannedRequests(in: container, planner: planner) else { return }

        var requestsByIdentifier: [String: RecurringNotificationRequest] = [:]
        for request in planned {
            requestsByIdentifier[request.identifier] = request
        }

        let center = UNUserNotificationCenter.current()
        let staleIdentifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { identifier in
                identifier.hasPrefix(RecurringNotificationPlanner.identifierPrefix) && requestsByIdentifier[identifier] == nil
            }
        center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)

        for (identifier, request) in requestsByIdentifier {
            let systemRequest = notificationRequest(
                identifier: identifier,
                for: request,
                calendar: planner.calendar
            )
            try? await center.add(systemRequest)
        }

        await clearSettledDeliveredNotifications(in: container, planner: planner, center: center)
    }

    private func clearSettledDeliveredNotifications(
        in container: ModelContainer,
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
              let rules = try? ModelContext(container).fetch(FetchDescriptor<RecurringTransactionRule>())
        else { return }
        center.removeDeliveredNotifications(withIdentifiers: planner.identifiersToClear(delivered: delivered, rules: rules))
    }

    private func plannedRequests(
        in container: ModelContainer,
        planner: RecurringNotificationPlanner
    ) -> [RecurringNotificationRequest]? {
        let context = ModelContext(container)
        do {
            guard let currency = try MonthService.shared.latestMonth(in: context)?.currency else { return [] }
            let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
            let months = try context.fetch(FetchDescriptor<Month>())
            return planner.requests(
                for: rules,
                currency: currency,
                now: .now,
                months: months
            )
        } catch {
            return nil
        }
    }

    private func notificationRequest(
        identifier: String,
        for request: RecurringNotificationRequest,
        calendar: Calendar
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.threadIdentifier = Self.threadIdentifier
        content.userInfo = RecurringNotificationPayload(
            ruleID: request.ruleID,
            occurrenceDate: request.occurrenceDate
        ).userInfo
        if request.canBeConfirmed {
            content.categoryIdentifier = request.isIncome
                ? RecurringNotificationAction.incomeCategory
                : RecurringNotificationAction.expenseCategory
        }
        switch request.kind {
        case .due:
            content.sound = .default
        case .addedAutomatically:
            content.interruptionLevel = .passive
        }

        let fireComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: request.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
    }
}
