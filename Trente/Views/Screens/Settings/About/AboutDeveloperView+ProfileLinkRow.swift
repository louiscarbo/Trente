//
//  AboutDeveloperView+ProfileLinkRow.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

extension AboutDeveloperView {
    struct ProfileLinkRow: View {
        let title: LocalizedStringResource
        let systemImage: String
        let url: URL

        var body: some View {
            Link(destination: url) {
                ExternalLinkLabel(title: title, systemImage: systemImage)
                    .padding(.vertical, DesignSystem.Spacing.medium.rawValue)
            }
            .buttonStyle(.plain)
        }
    }
}
