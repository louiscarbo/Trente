//
//  ApplePaySection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ApplePaySection: View {
    let onSetUp: () -> Void

    var body: some View {
        Section {
            Button(action: onSetUp) {
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
