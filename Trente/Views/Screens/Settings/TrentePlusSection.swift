//
//  TrentePlusSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct TrentePlusSection: View {
    let isSubscribed: Bool
    let onDiscover: () -> Void
    let onManage: () -> Void

    var body: some View {
        Section {
            if isSubscribed {
                Button("Manage Subscription", systemImage: "creditcard", action: onManage)
            } else {
                Button("Discover Trente+", systemImage: "sparkles", action: onDiscover)
            }
        } header: {
            Text("Trente+")
        } footer: {
            if isSubscribed {
                Text("Thank you for supporting Trente!")
            } else {
                Text("Attach notes and images to your transactions, and support an independent developer.")
            }
        }
    }
}

#Preview {
    Form {
        TrentePlusSection(isSubscribed: false, onDiscover: {}, onManage: {})
        TrentePlusSection(isSubscribed: true, onDiscover: {}, onManage: {})
    }
    .formStyle(.grouped)
}
