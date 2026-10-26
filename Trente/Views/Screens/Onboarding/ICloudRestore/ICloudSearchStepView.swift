//
//  ICloudSearchStepView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/10/2026.
//

import SwiftUI

struct ICloudSearchStepView: View {
    let onSetUpAsNew: () -> Void

    var body: some View {
        OnboardingStepLayout(compactArrangement: .secondaryBelow) {
            VStack(spacing: .large) {
                Image(systemName: "icloud")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse)
                OnboardingHeader(
                    title: "Looking for your data",
                    subtitle: "Checking your iCloud account for months and transactions from your other devices.",
                    alignment: .center
                )
            }
        } secondary: {
            ProgressView()
                .frame(maxWidth: .infinity)
        } actions: {
            Button("Set Up as New", action: onSetUpAsNew)
                .buttonStyle(TrenteSecondaryButtonStyle())
        }
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 844)) {
    ICloudSearchStepView {}
}

#Preview("Regular", traits: .fixedLayout(width: 1200, height: 800)) {
    ICloudSearchStepView {}
}
