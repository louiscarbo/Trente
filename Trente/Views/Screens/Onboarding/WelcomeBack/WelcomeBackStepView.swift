//
//  WelcomeBackStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/10/2026.
//

import SwiftUI

struct WelcomeBackStepView: View {
    let monthCount: Int
    let transactionCount: Int
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepLayout(compactArrangement: .secondaryBelow) {
            VStack(spacing: .large) {
                StickerView(imageName: "Trente Pig Sticker", rotation: .zero)
                    .frame(width: 170)
                OnboardingHeader(
                    title: "Welcome back!",
                    subtitle: """
                        We found your data in iCloud: ^[\(monthCount) month](inflect: true) and \
                        ^[\(transactionCount) transaction](inflect: true). It's all here, ready to pick up where you left off.
                        """,
                    alignment: .center
                )
            }
        } secondary: {
            EmptyView()
        } actions: {
            OnboardingContinueButton(title: "Continue", action: onContinue)
        }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    WelcomeBackStepView(monthCount: 14, transactionCount: 312) {}
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    WelcomeBackStepView(monthCount: 1, transactionCount: 1) {}
}
