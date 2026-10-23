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
                        Text(Decimal(budgetCents) / 100, format: .currency(code: currency.isoCode).precision(.fractionLength(0...2)))
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

private struct AdaptiveCategoryLegend: View {
    let isInPrimaryColumn: Bool

    @Environment(\.isOnboardingLayoutRegular) private var isRegular

    var body: some View {
        if isRegular == isInPrimaryColumn {
            CategoryLegend()
        }
    }
}

struct CategoryLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(BudgetCategory.allCases) { category in
                HStack(spacing: DesignSystem.Spacing.small.rawValue) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(category.shortExamples)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, 4)
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
