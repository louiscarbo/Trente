//
//  NotificationsStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

enum NotificationReason: CaseIterable {
    case applePay
    case recurring

    var title: LocalizedStringKey {
        switch self {
        case .applePay:
            "Log Apple Pay payments"
        case .recurring:
            "Stay ahead of recurring transactions"
        }
    }

    var detail: LocalizedStringKey {
        switch self {
        case .applePay:
            "Trente taps you after each payment, so logging it takes a second."
        case .recurring:
            "Get a heads-up before rent, subscriptions and other recurring transactions are due."
        }
    }

    var systemImage: String {
        switch self {
        case .applePay:
            "wallet.pass"
        case .recurring:
            "arrow.trianglehead.counterclockwise.rotate.90"
        }
    }
}

struct NotificationsStepView: View {
    let reasons: [NotificationReason]
    let currency: Currency
    let status: NotificationPermissionStatus
    let onEnable: () -> Void
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepLayout {
            VStack(alignment: .leading, spacing: .large) {
                OnboardingHeader(
                    title: "Stay in the loop",
                    subtitle: "Notifications keep your budget up to date without opening the app."
                )
                VStack(alignment: .leading, spacing: .medium) {
                    ForEach(reasons, id: \.self) { reason in
                        reasonRow(reason)
                    }
                }
            }
        } secondary: {
            VStack(spacing: .medium) {
                StickerView(imageName: "Trente Pig Sticker", rotation: .degrees(6))
                    .frame(width: 96, height: 96)
                ForEach(reasons, id: \.self) { reason in
                    preview(for: reason)
                }
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } actions: {
            actions
        }
    }

    private func reasonRow(_ reason: NotificationReason) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(reason.title)
                    .bold()
                Text(reason.detail)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: reason.systemImage)
                .foregroundStyle(.tint)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func preview(for reason: NotificationReason) -> some View {
        switch reason {
        case .applePay:
            NotificationPreview(
                title: WalletNotificationService.title(amountCents: -4_20, currency: currency, title: "Café"),
                message: WalletNotificationService.body
            )
        case .recurring:
            NotificationPreview(
                title: WalletNotificationService.title(amountCents: -850_00, currency: currency, title: "Rent"),
                message: String(localized: "Due tomorrow")
            )
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
        .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    NotificationsStepView(
        reasons: NotificationReason.allCases,
        currency: Currencies.currency(for: "EUR")!,
        status: .notDetermined,
        onEnable: {},
        onOpenSettings: {},
        onContinue: {}
    )
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    NotificationsStepView(
        reasons: [.recurring],
        currency: Currencies.currency(for: "USD")!,
        status: .denied,
        onEnable: {},
        onOpenSettings: {},
        onContinue: {}
    )
}
