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
                            benefit("Notes and images on any transaction")
                            benefit("Automatic recurring transactions")
                            #if os(iOS)
                            benefit("Pick your app icon")
                            #endif
                            benefit("Support an indie developer")
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

    private func benefit(_ title: LocalizedStringKey) -> some View {
        Label(title, systemImage: "checkmark.circle.fill")
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
