//
//  WelcomeStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct WelcomeStepView: View {
    let percentages: [BudgetCategory: Int]
    let onGetStarted: () -> Void

    var body: some View {
        OnboardingStepLayout {
            OnboardingHeader(
                title: "Take control of your budget.",
                subtitle: "Trente splits your budget into Needs, Wants and Savings, so you always know what's left this month.",
                isHero: true
            )
        } secondary: {
            AdaptiveCategoryTreemap(percentages: percentages)
                .frame(minHeight: 280)
        } actions: {
            OnboardingContinueButton(title: "Get Started", action: onGetStarted)
        }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    WelcomeStepView(percentages: OnboardingModel.suggestedPercentages) {}
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    WelcomeStepView(percentages: OnboardingModel.suggestedPercentages) {}
}
