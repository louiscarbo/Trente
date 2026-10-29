//
//  FAQView+ContactPrompt.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

extension FAQView {
    struct ContactPrompt: View {
        let contactURL: URL?
        let contactAddress: String

        var body: some View {
            VStack(alignment: .leading, spacing: .small) {
                Text("Can't find your answer?")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("Email the developer. I reply to every message!")
                    .foregroundStyle(.secondary)
                ContactButton(url: contactURL, address: contactAddress) {
                    Label("Send Me an Email", systemImage: "envelope")
                }
                .buttonStyle(TrentePrimaryButtonStyle())
                .padding(.top, DesignSystem.Spacing.small.rawValue)
            }
            .padding(.vertical, DesignSystem.Spacing.small.rawValue)
        }
    }
}

#Preview {
    Form {
        FAQView.ContactPrompt(contactURL: nil, contactAddress: SupportMail.address)
    }
    .formStyle(.grouped)
}
