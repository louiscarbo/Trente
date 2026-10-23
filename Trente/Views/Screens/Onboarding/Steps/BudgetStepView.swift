//
//  BudgetStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct BudgetStepView: View {
    @Binding var startDate: Date
    @Binding var currency: Currency
    @Binding var budgetCents: Int
    let canContinue: Bool
    let onContinue: () -> Void

    @FocusState private var isAmountFocused: Bool

    var body: some View {
        OnboardingStepLayout {
            OnboardingHeader(
                title: "Your monthly budget",
                subtitle: "How much do you expect to earn this month? Trente splits it for you on the next step."
            )
        } secondary: {
            OnboardingScrollPane {
                GroupBox(label: Label("Ideal Budget", systemImage: currency.sfSymbolGaugeName)) {
                    IdealBudgetField(
                        amountCents: $budgetCents,
                        currency: currency,
                        isFocused: $isAmountFocused
                    )
                }
                .groupBoxStyle(TrenteGroupBoxStyle())

                GroupBox(label: Label("Month Details", systemImage: "calendar")) {
                    VStack(spacing: .medium) {
                        MonthStartDatePicker(startDate: $startDate)
                        MonthCurrencyPicker(currency: $currency)
                    }
                }
                .groupBoxStyle(TrenteGroupBoxStyle())

                Label(
                    "Income varies? Enter a careful estimate. You can change it for each new month.",
                    systemImage: "lightbulb"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } actions: {
            OnboardingContinueButton(title: "Continue", isEnabled: canContinue, action: onContinue)
        }
        .keyboardDismissButton(isVisible: isAmountFocused) { isAmountFocused = false }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    @Previewable @State var startDate: Date = .now
    @Previewable @State var currency: Currency = Currencies.currency(for: "EUR")!
    @Previewable @State var budgetCents: Int = 2000_00

    BudgetStepView(
        startDate: $startDate,
        currency: $currency,
        budgetCents: $budgetCents,
        canContinue: budgetCents > 0
    ) {}
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    @Previewable @State var startDate: Date = .now
    @Previewable @State var currency: Currency = Currencies.currency(for: "EUR")!
    @Previewable @State var budgetCents: Int = 0

    BudgetStepView(
        startDate: $startDate,
        currency: $currency,
        budgetCents: $budgetCents,
        canContinue: budgetCents > 0
    ) {}
}
