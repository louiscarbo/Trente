//
//  ApplePaySection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ApplePaySection: View {
    let onGetShortcut: () -> Void

    var body: some View {
        Section {
            Button(action: onGetShortcut) {
                ExternalLinkLabel(title: "Get the Shortcut", systemImage: "square.and.arrow.down")
            }
            NavigationLink {
                ApplePaySetupView(onGetShortcut: onGetShortcut)
            } label: {
                Label("How to Set It Up", systemImage: "list.number")
            }
        } header: {
            Text("Apple Pay")
        }
    }
}

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
        Form {
            ApplePaySection {}
        }
        .formStyle(.grouped)
    }
}

#Preview("Setup") {
    NavigationStack {
        ApplePaySetupView {}
    }
}
