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
            OnboardingHeader(
                title: "Split your budget",
                subtitle: "We started you at 50/30/20. Move the sliders until there's nothing left to split."
            )
        } secondary: {
            OnboardingScrollPane {
                GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
                    IncomeRepartitionComponent(
                        repartition: $repartition,
                        amountToSplit: budgetCents,
                        formatter: currency.roundFormatter,
                        isRepartitionComplete: $isRepartitionComplete
                    )
                    .id(budgetCents)
                }
                .groupBoxStyle(TrenteGroupBoxStyle())

                CategoryLegend()
            }
        } actions: {
            OnboardingContinueButton(title: "Continue", isEnabled: isRepartitionComplete, action: onContinue)
        }
    }
}

struct CategoryLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            ForEach(BudgetCategory.allCases) { category in
                HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.small.rawValue) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(category.name)
                        .bold()
                    Text(category.shortExamples)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
