//
//  ContactButton.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ContactButton<Content: View>: View {
    let url: URL?
    let address: String
    @ViewBuilder let label: () -> Content

    @Environment(\.openURL) private var openURL
    @State private var isShowingFallback = false

    var body: some View {
        Button(action: contact, label: label)
            .alert("Couldn't Open Mail", isPresented: $isShowingFallback) {
                Button("Copy Address") {
                    Pasteboard.copy(address)
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("You can write to \(address) from any email app.")
            }
    }

    private func contact() {
        guard let url else {
            isShowingFallback = true
            return
        }
        openURL(url) { accepted in
            if !accepted {
                isShowingFallback = true
            }
        }
    }
}

#Preview {
    ContactButton(url: nil, address: SupportMail.address) {
        Text("Send Me an Email")
    }
}
