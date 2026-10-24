//
//  ExternalLinkLabel.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ExternalLinkLabel: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let systemImage: String

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: systemImage)
            }
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
            ExternalLinkLabel(
                title: "Rate on the App Store",
                detail: "Opens Trente's App Store page",
                systemImage: "star"
            )
        }
    }
    .formStyle(.grouped)
}
