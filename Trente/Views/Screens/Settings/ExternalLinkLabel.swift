//
//  ExternalLinkLabel.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ExternalLinkLabel: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
    }
}

#Preview {
    Form {
        Link(destination: ExternalLinks.writeReview) {
            ExternalLinkLabel(title: "Rate on the App Store", systemImage: "star")
        }
    }
    .formStyle(.grouped)
}
