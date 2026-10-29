//
//  SplitStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct SplitStepView: View {
    @Binding var repartition: [BudgetCategory: Int]
    @Binding var isRepartitionComplete: Bool
    let budgetCents: Int
    let currency: Currency
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepLayout {
            VStack(spacing: .large) {
                OnboardingHeader(
                    title: "Split your budget",
                    subtitle: "We start you on the 50/30/20 rule. Adjust it until it fits your life, you can change it every month."
                )
                AdaptiveCategoryLegend(isInPrimaryColumn: true)
            }
        } secondary: {
            OnboardingScrollPane {
                GroupBox(label: Label("Ideal Budget", systemImage: currency.sfSymbolName ?? currency.sfSymbolGaugeName)) {
                    VStack(spacing: .medium) {
                        Text(Double(budgetCents) / 100, format: .budget(currency.isoCode))
                            .font(.title)
                            .bold()
                            .frame(maxWidth: .infinity)

                        IncomeRepartitionComponent(
                            repartition: $repartition,
                            amountToSplit: budgetCents,
                            formatter: currency.roundFormatter,
                            isRepartitionComplete: $isRepartitionComplete
                        )
                        .id(budgetCents)
                    }
                }
                .groupBoxStyle(TrenteGroupBoxStyle())

                AdaptiveCategoryLegend(isInPrimaryColumn: false)
            }
        } actions: {
            OnboardingContinueButton(title: "Continue", isEnabled: isRepartitionComplete, action: onContinue)
        }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    @Previewable @State var repartition = OnboardingModel.suggestedRepartition(for: 2000_00)
    @Previewable @State var isRepartitionComplete = false

    SplitStepView(
        repartition: $repartition,
        isRepartitionComplete: $isRepartitionComplete,
        budgetCents: 2000_00,
        currency: Currencies.currency(for: "EUR")!
    ) {}
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    @Previewable @State var repartition = OnboardingModel.suggestedRepartition(for: 1234_00)
    @Previewable @State var isRepartitionComplete = false

    SplitStepView(
        repartition: $repartition,
        isRepartitionComplete: $isRepartitionComplete,
        budgetCents: 1234_00,
        currency: Currencies.currency(for: "EUR")!
    ) {}
}
