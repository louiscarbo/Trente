//
//  ApplePayStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct ApplePayStepView: View {
    let currency: Currency
    let onSetUp: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepLayout {
            OnboardingHeader(
                title: "Log Apple Pay purchases automatically",
                subtitle: "Your card payments show up in Trente, ready to review. One-time setup, about 2 minutes, guided step by step."
            )
        } secondary: {
            OnboardingScrollPane {
                NotificationPreview(
                    title: NotificationText.amountTitle(amountCents: -4_50, currency: currency, title: String(localized: "Bakery")),
                    message: WalletNotificationService.body
                )
                SetupSteps(
                    title: "Once it's set up",
                    steps: [
                        "You pay with Apple Pay.",
                        "Trente sends you a notification.",
                        "You tap it to log the purchase."
                    ]
                )
                Label(
                    "Trente only receives the merchant name and the amount. Never your card details.",
                    systemImage: "lock.fill"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 370)
            .frame(maxWidth: .infinity)
        } actions: {
            OnboardingContinueButton(title: "Set Up · about 2 min", action: onSetUp)
            Button(action: onContinue) {
                Text("Set Up Later")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TrenteSecondaryButtonStyle())
        }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    ApplePayStepView(currency: Currencies.currency(for: "EUR")!, onSetUp: {}, onContinue: {})
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    ApplePayStepView(currency: Currencies.currency(for: "USD")!, onSetUp: {}, onContinue: {})
}
