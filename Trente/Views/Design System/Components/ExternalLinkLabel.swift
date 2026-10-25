//
//  ExternalLinkLabel.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ExternalLinkLabel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            content()
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

extension ExternalLinkLabel where Content == Label<Text, Image> {
    init(title: LocalizedStringResource, systemImage: String) {
        self.init {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
            }
        }
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
