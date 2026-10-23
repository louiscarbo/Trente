//
//  AllSetStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct AllSetStepView: View {
    let month: Month?
    let onStartTracking: () -> Void

    var body: some View {
        OnboardingStepLayout(compactArrangement: .secondaryBelow) {
            VStack(spacing: .large) {
                StickerView(imageName: "Trente Rocket Sticker", rotation: .zero)
                    .frame(width: 170)
                OnboardingHeader(
                    title: "You're all set!",
                    subtitle: "Your first month starts today. Log expenses as you go and Trente shows you what's left.",
                    alignment: .center
                )
            }
        } secondary: {
            if let month {
                CurrentMonthRowView(currentMonth: month)
                    .allowsHitTesting(false)
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity)
            }
        } actions: {
            OnboardingContinueButton(title: "Start Tracking", action: onStartTracking)
        }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    AllSetStepView(month: Month.sampleData.first) {}
        .modelContainer(DataProvider.shared.modelContainer)
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    AllSetStepView(month: Month.sampleData.first) {}
        .modelContainer(DataProvider.shared.modelContainer)
}
