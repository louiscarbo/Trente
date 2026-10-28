//
//  CreditsView+Row.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

extension CreditsView {
    struct Row: View {
        let credit: Credit

        var body: some View {
            if let url = credit.url {
                Link(destination: url) {
                    ExternalLinkLabel {
                        content
                    }
                }
            } else {
                content
            }
        }

        private var content: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(credit.title)
                    .foregroundStyle(.primary)
                Text(credit.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
