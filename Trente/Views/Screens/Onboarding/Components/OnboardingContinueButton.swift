//
//  OnboardingContinueButton.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

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
        OnboardingContinueButton(title: "Continue") {}
        OnboardingContinueButton(title: "Continue", isEnabled: false) {}
    }
    .padding()
}
