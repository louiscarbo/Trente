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

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            Text(title)
                .font(.largeTitle)
                .bold()
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct OnboardingContinueButton: View {
    let title: LocalizedStringKey
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(TrentePrimaryButtonStyle())
        .disabled(!isEnabled)
        .keyboardShortcut(.defaultAction)
    }
}

#Preview {
    VStack(spacing: .large) {
        OnboardingHeader(
            title: "Your monthly budget",
            subtitle: "How much do you expect to earn this month?"
        )
        OnboardingContinueButton(title: "Continue") {}
        OnboardingContinueButton(title: "Continue", isEnabled: false) {}
    }
    .padding()
}
