//
//  ApplePaySetupView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ApplePaySetupView: View {
    let onGetShortcut: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .large) {
                ApplePaySetupGuide()

                Button(action: onGetShortcut) {
                    Text("Get the Shortcut")
                }
                .buttonStyle(TrentePrimaryButtonStyle())
            }
            .padding()
        }
        .navigationTitle("Apple Pay")
    }
}

#Preview {
    NavigationStack {
        ApplePaySetupView {}
    }
}
