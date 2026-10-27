//
//  WalletNotificationService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Foundation
import UserNotifications

final class WalletNotificationService: Sendable {
    static let shared = WalletNotificationService()
    static let pendingTransactionIDKey = "pendingTransactionID"

    private init() {}

    @MainActor
    func post(for pending: PendingTransaction, currency: Currency) async throws {
        let content = UNMutableNotificationContent()
        content.title = NotificationText.amountTitle(
            amountCents: pending.amountCents,
            currency: currency,
            title: pending.title
        )
        content.body = Self.body
        content.sound = .default
        content.userInfo = [Self.pendingTransactionIDKey: pending.id.uuidString]

        let request = UNNotificationRequest(
            identifier: pending.id.uuidString,
            content: content,
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    static var body: String {
        String(localized: "Tap here to log it in Trente")
    }

    func postDebugFailure(_ message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Wallet intake failed"
        content.body = message
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
