//
//  SubscriptionView+MarketingHeader.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI
import StoreKit

extension SubscriptionView {
    struct MarketingHeader: View {
        @ScaledMetric(relativeTo: .headline) private var iconSize = 36.0

        var body: some View {
            VStack(spacing: .large) {
                StickerView(imageName: "Trente Pig Sticker", rotation: .zero)
                    .frame(width: 170)

                VStack(spacing: 6) {
                    Text("Trente+")
                        .font(.largeTitle)
                        .bold()
                    Text("Let Trente+ do the typing, and unlock new features.")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                GroupBox(label: Label("Included with Trente+", systemImage: "sparkles")) {
                    VStack(alignment: .leading, spacing: .medium) {
                        ForEach(TrentePlusBenefit.all) { benefit in
                            benefitRow(benefit)
                        }
                    }
                }
                .groupBoxStyle(TrenteGroupBoxStyle())
            }
            .padding()
        }

        private func benefitRow(_ benefit: TrentePlusBenefit) -> some View {
            HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                Image(systemName: benefit.systemImage)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: iconSize, height: iconSize)
                    .background(benefit.tint.gradient, in: .rect(cornerRadius: iconSize / 4))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(benefit.title)
                        .font(.headline)
                    Text(benefit.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview("Marketing Header", traits: .sizeThatFitsLayout) {
    SubscriptionView.MarketingHeader()
        .frame(width: 402)
}
