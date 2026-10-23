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
    nonisolated static let occurrenceDateKey = "occurrenceDate"

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
        let planner = RecurringNotificationPlanner()
        guard let planned = plannedRequests(in: container, planner: planner) else { return }

        var requestsByIdentifier: [String: RecurringNotificationRequest] = [:]
        for request in planned {
            guard let identifier = Self.identifier(for: request, calendar: planner.calendar) else { continue }
            requestsByIdentifier[identifier] = request
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
    }

    nonisolated static func identifier(
        for request: RecurringNotificationRequest,
        calendar: Calendar = .current
    ) -> String? {
        guard !request.ruleID.isTemporary else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let ruleData = try? encoder.encode(request.ruleID) else { return nil }

        let components = calendar.dateComponents([.year, .month, .day], from: request.occurrenceDate)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }
        let dayString = String(format: "%04ld-%02ld-%02ld", year, month, day)
        return "\(identifierPrefix)\(ruleData.base64EncodedString()).\(dayString)"
    }

    private static var rescheduleTriggers: [Notification.Name] {
        var names: [Notification.Name] = [ModelContext.didSave, .NSCalendarDayChanged]
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
            return planner.requests(
                for: rules,
                currency: currency,
                now: .now
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
        content.userInfo = [Self.occurrenceDateKey: request.occurrenceDate.timeIntervalSinceReferenceDate]
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
