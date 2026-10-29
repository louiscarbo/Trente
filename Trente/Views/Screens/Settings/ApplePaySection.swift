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
            NavigationLink {
                ApplePaySetupView(onGetShortcut: onGetShortcut)
            } label: {
                Label("Connect Trente to Apple Pay", systemImage: "creditcard")
            }
        } header: {
            Text("Apple Pay")
        }
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
