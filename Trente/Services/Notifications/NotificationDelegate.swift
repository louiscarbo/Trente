//
//  NotificationDelegate.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private var container: ModelContainer?

    override private init() {}

    func start(container: ModelContainer) {
        guard self.container == nil else { return }
        self.container = container
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories(RecurringNotificationAction.categories)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let pendingTransactionID = (userInfo[WalletNotificationService.pendingTransactionIDKey] as? String)
            .flatMap(UUID.init(uuidString:))
        let recurringAction = RecurringNotificationAction(rawValue: response.actionIdentifier)
        let recurringPayload = RecurringNotificationPayload(userInfo: userInfo)
        Task { @MainActor in
            if let recurringAction, let recurringPayload, let container {
                _ = try? RecurringNotificationResponder.handle(
                    recurringAction,
                    payload: recurringPayload,
                    in: container.mainContext
                )
            } else if let pendingTransactionID {
                PendingTransactionRouter.shared.presentedPendingTransactionID = pendingTransactionID
            }
            completionHandler()
        }
    }
}
