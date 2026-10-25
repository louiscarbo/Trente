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
            Button(action: onGetShortcut) {
                ExternalLinkLabel(title: "Get the Shortcut", systemImage: "square.and.arrow.down")
            }
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
                ApplePaySetupGuide(steps: steps)

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
