//
//  WalletNotificationService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Foundation
import UserNotifications

final class WalletNotificationService {
    static let shared = WalletNotificationService()
    static let pendingTransactionIDKey = "pendingTransactionID"

    private init() {}

    @MainActor
    func start() {
        #if os(iOS)
        UNUserNotificationCenter.current().delegate = WalletNotificationDelegate.shared
        // TODO: Move the permission request to onboarding.
        Task {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
        #endif
    }

    @MainActor
    func post(for pending: PendingTransaction, currency: Currency) async throws {
        let amount = (Double(abs(pending.amountCents)) / 100.0)
            .formatted(.currency(code: currency.isoCode))

        let content = UNMutableNotificationContent()
        content.title = [amount, pending.title, pending.category?.shortName]
            .compactMap { $0 }
            .joined(separator: " - ")
        content.body = String(localized: "Tap here to log it in Trente")
        content.sound = .default
        content.userInfo = [Self.pendingTransactionIDKey: pending.id.uuidString]

        let request = UNNotificationRequest(
            identifier: pending.id.uuidString,
            content: content,
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    func postDebugFailure(_ message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Wallet intake failed"
        content.body = message
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

final class WalletNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WalletNotificationDelegate()

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
        let idString = userInfo[WalletNotificationService.pendingTransactionIDKey] as? String
        Task { @MainActor in
            if let idString, let id = UUID(uuidString: idString) {
                PendingTransactionRouter.shared.presentedPendingTransactionID = id
            }
            completionHandler()
        }
    }
}
