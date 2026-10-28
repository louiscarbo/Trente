//
//  OnboardingHeader.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct OnboardingHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var alignment: HorizontalAlignment = .leading
    var isHero = false

    @ScaledMetric(relativeTo: .largeTitle) private var heroTitleSize = 46

    var body: some View {
        VStack(alignment: alignment, spacing: .small) {
            Text(title)
                .font(isHero ? .system(size: heroTitleSize, weight: .heavy) : .largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(alignment == .center ? .center : .leading)
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    VStack(spacing: .large) {
        OnboardingHeader(
            title: "Take control of your budget.",
            subtitle: "Trente splits your budget into Needs, Wants and Savings, so you always know what's left this month.",
            isHero: true
        )
        OnboardingHeader(
            title: "Your monthly budget",
            subtitle: "Think of it as the money you're free to spend each month, once taxes are taken care of."
        )
        OnboardingHeader(
            title: "Never miss an expense",
            subtitle: "When you pay with Apple Pay, Trente sends you a notification.",
            alignment: .center
        )
    }
    .padding()
}
