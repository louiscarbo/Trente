//
//  RecurringNotificationScheduler.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class RecurringNotificationScheduler {
    static let shared = RecurringNotificationScheduler()
    nonisolated static let identifierPrefix = "recurring."
    nonisolated static let threadIdentifier = "recurring"

    private let debounceDelay: Duration = .seconds(1)
    private var container: ModelContainer?
    private var observers: [any NSObjectProtocol] = []
    private var rescheduleTask: Task<Void, Never>?

    private init() {}

    func start(container: ModelContainer) {
        guard self.container == nil else { return }
        self.container = container
        observers = Self.rescheduleTriggers.map { name in
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { _ in
                MainActor.assumeIsolated {
                    RecurringNotificationScheduler.shared.scheduleReschedule()
                }
            }
        }
        scheduleReschedule()
    }

    func reschedule() async {
        guard let container else { return }
        guard await NotificationPermissionService().status() == .authorized else { return }
        let planner = RecurringNotificationPlanner(reminderTime: .stored())
        guard let planned = plannedRequests(in: container, planner: planner) else { return }

        var requestsByIdentifier: [String: RecurringNotificationRequest] = [:]
        for request in planned {
            requestsByIdentifier[Self.identifier(for: request, calendar: planner.calendar)] = request
        }

        let center = UNUserNotificationCenter.current()
        let staleIdentifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { identifier in
                identifier.hasPrefix(Self.identifierPrefix) && requestsByIdentifier[identifier] == nil
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

        await clearSettledDeliveredNotifications(in: container, center: center)
    }

    static func identifiersToClear(
        delivered: [(identifier: String, payload: RecurringNotificationPayload)],
        rules: [RecurringTransactionRule]
    ) -> [String] {
        delivered.compactMap { notification in
            guard let rule = rules.first(where: { rule in rule.id == notification.payload.ruleID }) else {
                return notification.identifier
            }
            return rule.isPending(on: notification.payload.occurrenceDate) ? nil : notification.identifier
        }
    }

    private func clearSettledDeliveredNotifications(in container: ModelContainer, center: UNUserNotificationCenter) async {
        let delivered = await center.deliveredNotifications().compactMap { notification -> (identifier: String, payload: RecurringNotificationPayload)? in
            let request = notification.request
            guard request.identifier.hasPrefix(Self.identifierPrefix),
                  let payload = RecurringNotificationPayload(userInfo: request.content.userInfo)
            else { return nil }
            return (request.identifier, payload)
        }
        guard !delivered.isEmpty,
              let rules = try? ModelContext(container).fetch(FetchDescriptor<RecurringTransactionRule>())
        else { return }
        center.removeDeliveredNotifications(withIdentifiers: Self.identifiersToClear(delivered: delivered, rules: rules))
    }

    nonisolated static func identifier(
        for request: RecurringNotificationRequest,
        calendar: Calendar = .current
    ) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: request.occurrenceDate)
        let dayString = String(
            format: "%04ld-%02ld-%02ld",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
        return "\(identifierPrefix)\(request.ruleID.uuidString).\(dayString)"
    }

    private static var rescheduleTriggers: [Notification.Name] {
        var names: [Notification.Name] = [ModelContext.didSave, .NSCalendarDayChanged, UserDefaults.didChangeNotification]
        #if os(iOS)
        names.append(UIApplication.didBecomeActiveNotification)
        #elseif os(macOS)
        names.append(NSApplication.didBecomeActiveNotification)
        #endif
        return names
    }

    private func scheduleReschedule() {
        let previousTask = rescheduleTask
        previousTask?.cancel()
        rescheduleTask = Task { [debounceDelay] in
            try? await Task.sleep(for: debounceDelay)
            await previousTask?.value
            guard !Task.isCancelled else { return }
            await RecurringNotificationScheduler.shared.reschedule()
        }
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
