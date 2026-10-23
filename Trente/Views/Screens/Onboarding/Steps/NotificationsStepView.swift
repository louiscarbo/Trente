//
//  NotificationsStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct NotificationsStepView: View {
    let currency: Currency
    let status: NotificationPermissionStatus
    let onEnable: () -> Void
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepLayout(compactArrangement: .secondaryAbove) {
            OnboardingHeader(
                title: "Never miss an expense",
                subtitle: "When you pay with Apple Pay, Trente sends you a notification. Tap it to review the expense and log it in one go.",
                alignment: .center
            )
        } secondary: {
            NotificationPreview(
                title: WalletNotificationService.title(amountCents: -4_50, currency: currency, title: "Boulangerie"),
                message: WalletNotificationService.body
            )
            .frame(maxWidth: 370)
            .frame(maxWidth: .infinity)
        } actions: {
            actions
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch status {
        case .notDetermined:
            OnboardingContinueButton(title: "Turn On Notifications", action: onEnable)
            notNowButton
        case .denied:
            OnboardingContinueButton(title: "Open Settings", action: onOpenSettings)
            notNowButton
        case .authorized:
            OnboardingContinueButton(title: "Continue", action: onContinue)
        }
    }

    private var notNowButton: some View {
        Button(action: onContinue) {
            Text("Not Now")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(TrenteSecondaryButtonStyle())
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    NotificationsStepView(
        currency: Currencies.currency(for: "EUR")!,
        status: .notDetermined,
        onEnable: {},
        onOpenSettings: {},
        onContinue: {}
    )
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    NotificationsStepView(
        currency: Currencies.currency(for: "USD")!,
        status: .denied,
        onEnable: {},
        onOpenSettings: {},
        onContinue: {}
    )
}
