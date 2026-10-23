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
        OnboardingStepLayout {
            VStack(alignment: .leading, spacing: .medium) {
                StickerView(imageName: "Trente Rocket Sticker", rotation: .degrees(8))
                    .frame(width: 88, height: 88)
                OnboardingHeader(
                    title: "You're all set",
                    subtitle: "Your first month is ready. Add income and expenses as they come, and Trente keeps the split for you."
                )
            }
        } secondary: {
            if let month {
                CurrentMonthRowView(currentMonth: month)
                    .allowsHitTesting(false)
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
