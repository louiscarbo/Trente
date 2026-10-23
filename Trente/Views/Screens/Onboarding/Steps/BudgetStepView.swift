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
                subtitle: "Think of it as the money you're free to spend each month, once taxes are taken care of."
            )
        } secondary: {
            OnboardingScrollPane {
                GroupBox(label: Label("Month Details", systemImage: "calendar")) {
                    VStack(spacing: .medium) {
                        MonthStartDatePicker(startDate: $startDate)
                        MonthCurrencyPicker(currency: $currency)
                    }
                }
                .groupBoxStyle(TrenteGroupBoxStyle())

                GroupBox(label: Label("Ideal Budget", systemImage: currency.sfSymbolName ?? currency.sfSymbolGaugeName)) {
                    IdealBudgetField(
                        amountCents: $budgetCents,
                        currency: currency,
                        isFocused: $isAmountFocused
                    )
                }
                .groupBoxStyle(TrenteGroupBoxStyle())

                incomeVariesTip
            }
        } actions: {
            OnboardingContinueButton(title: "Continue", isEnabled: canContinue, action: onContinue)
        }
        .keyboardDismissButton(isVisible: isAmountFocused) { isAmountFocused = false }
    }

    private var incomeVariesTip: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("Income varies?")
                Text("Use your best estimate. Log extra income as it comes in, and adjust next month's budget.")
                    .font(.footnote)
            }
        } icon: {
            Image(systemName: "sparkles")
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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
