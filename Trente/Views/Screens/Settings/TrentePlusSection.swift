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
            VStack(spacing: .medium) {
                HStack(spacing: DesignSystem.Spacing.large.rawValue) {
                    StickerView(imageName: "Trente Pig Sticker")
                        .frame(width: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trente+")
                            .font(.headline)
                            .bold()
                        if isSubscribed {
                            Text("You're a Trente+ member. Thank you!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(TrentePlusBenefit.all) { benefit in
                                benefitRow(benefit.title)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if isSubscribed {
                    Button("Manage Subscription", action: onManage)
                        .buttonStyle(TrenteSecondaryButtonStyle())
                } else {
                    Button("See Plans", action: onDiscover)
                        .buttonStyle(TrentePrimaryButtonStyle())
                }
            }
            .padding(.vertical, DesignSystem.Spacing.small.rawValue)
        }
    }

    private func benefitRow(_ title: LocalizedStringResource) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    Form {
        TrentePlusSection(isSubscribed: false, onDiscover: {}, onManage: {})
        TrentePlusSection(isSubscribed: true, onDiscover: {}, onManage: {})
    }
    .formStyle(.grouped)
}
