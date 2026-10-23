//
//  ApplePaySection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ApplePaySection: View {
    let setupSteps: [LocalizedStringKey]
    let onGetShortcut: () -> Void

    var body: some View {
        Section {
            Button("Get the Shortcut", systemImage: "square.and.arrow.down", action: onGetShortcut)
            NavigationLink {
                ApplePaySetupView(steps: setupSteps, onGetShortcut: onGetShortcut)
            } label: {
                Label("How to Set It Up", systemImage: "list.number")
            }
        } header: {
            Text("Apple Pay")
        }
    }
}

struct ApplePaySetupView: View {
    let steps: [LocalizedStringKey]
    let onGetShortcut: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .large) {
                ShortcutsSetupCard(
                    title: "In the Shortcuts app",
                    systemImage: "creditcard",
                    steps: steps
                )

                Label(
                    "Trente only receives the merchant name and the amount. Never your card details.",
                    systemImage: "lock.fill"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

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
        Form {
            ApplePaySection(setupSteps: ShortcutsSetupCard.applePaySetupSteps) {}
        }
        .formStyle(.grouped)
    }
}

#Preview("Setup") {
    NavigationStack {
        ApplePaySetupView(steps: ShortcutsSetupCard.applePaySetupSteps) {}
    }
}
