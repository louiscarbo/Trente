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
    static let opensPaywallKey = "opensPaywall"

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

    @MainActor
    func postLimitReached(amountCents: Int, title: String, currency: Currency) async throws {
        let content = UNMutableNotificationContent()
        content.title = Self.limitReachedTitle
        content.body = Self.limitReachedBody(amountCents: amountCents, currency: currency, title: title)
        content.sound = .default
        content.userInfo = [Self.opensPaywallKey: true]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    static var limitReachedTitle: String {
        String(localized: "Apple Pay limit reached")
    }

    static func limitReachedBody(amountCents: Int, currency: Currency, title: String) -> String {
        let amount = NotificationText.amount(cents: amountCents, currency: currency)
        return String(localized: "\(amount) at \(title) wasn't logged. Get unlimited Apple Pay logging with Trente+.")
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
