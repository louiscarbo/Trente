//
//  NotificationsStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct NotificationsStepView: View {
    let currency: Currency
    let showsApplePay: Bool
    let status: NotificationPermissionStatus
    let onEnable: () -> Void
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepLayout(compactArrangement: .secondaryAbove) {
            OnboardingHeader(
                title: "Never miss an expense",
                subtitle: subtitle,
                alignment: .center
            )
        } secondary: {
            VStack(spacing: .large) {
                NotificationPreview(
                    title: NotificationText.amountTitle(amountCents: -800_00, currency: currency, title: String(localized: "Rent")),
                    message: RecurringNotificationPlanner.body(for: .due, isIncome: false)
                )
                if showsApplePay {
                    NotificationPreview(
                        title: NotificationText.amountTitle(amountCents: -4_50, currency: currency, title: "Boulangerie"),
                        message: WalletNotificationService.body
                    )
                }
            }
            .frame(maxWidth: 370)
            .frame(maxWidth: .infinity)
        } actions: {
            actions
        }
    }

    private var subtitle: LocalizedStringKey {
        if showsApplePay {
            """
            Trente tells you when a new month starts and when a recurring payment like rent is due. \
            Once Apple Pay is set up, it also sends you a notification after each purchase so you can log it in one go.
            """
        } else {
            "Trente tells you when a new month starts and when a recurring payment like rent is due, so you can mark it as paid right from the notification."
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
        showsApplePay: true,
        status: .notDetermined,
        onEnable: {},
        onOpenSettings: {},
        onContinue: {}
    )
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    NotificationsStepView(
        currency: Currencies.currency(for: "USD")!,
        showsApplePay: false,
        status: .denied,
        onEnable: {},
        onOpenSettings: {},
        onContinue: {}
    )
}
