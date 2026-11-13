//
//  ApplePayStepView+SetupSteps.swift
//  Trente
//

import SwiftUI

extension ApplePayStepView {
    struct SetupSteps: View {
        let title: LocalizedStringKey
        let steps: [LocalizedStringKey]

        @ScaledMetric(relativeTo: .footnote) private var badgeSize = 24.0

        var body: some View {
            VStack(alignment: .leading, spacing: .medium) {
                Text(title)
                    .font(.headline)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                        Text(verbatim: String(index + 1))
                            .font(.footnote.bold())
                            .foregroundStyle(.background)
                            .frame(width: badgeSize, height: badgeSize)
                            .background(.primary, in: .circle)
                            .accessibilityHidden(true)
                        Text(step)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ApplePayStepView.SetupSteps(
        title: "Once it's set up",
        steps: [
            "You pay with Apple Pay.",
            "Trente sends you a notification.",
            "You tap it to log the purchase."
        ]
    )
    .padding()
    .frame(width: 370)
}
