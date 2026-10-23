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
            VStack(alignment: .leading, spacing: .medium) {
                StickerView(imageName: "Trente Pig Sticker")
                    .frame(width: 88, height: 88)
                OnboardingHeader(
                    title: "Welcome to Trente",
                    subtitle: "Split every month into needs, wants and savings with the 50/30/20 rule, and always know what's left."
                )
            }
        } secondary: {
            AdaptiveCategoryTreemap(percentages: percentages)
                .frame(minHeight: 280)
        } actions: {
            OnboardingContinueButton(title: "Get Started", action: onGetStarted)
        }
    }
}

private struct AdaptiveCategoryTreemap: View {
    let percentages: [BudgetCategory: Int]

    @Environment(\.isOnboardingLayoutRegular) private var isRegular

    var body: some View {
        CategoryTreemap(percentages: percentages, isWide: isRegular)
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    WelcomeStepView(percentages: OnboardingModel.suggestedPercentages) {}
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    WelcomeStepView(percentages: OnboardingModel.suggestedPercentages) {}
}
