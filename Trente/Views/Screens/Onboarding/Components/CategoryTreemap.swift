//
//  CategoryTreemap.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct CategoryTreemap: View {
    let percentages: [BudgetCategory: Int]
    let isWide: Bool

    var body: some View {
        Group {
            if isWide {
                ProportionalStack(axis: .horizontal) {
                    needsSlab
                        .layoutWeight(1)
                    ProportionalStack {
                        slab(for: .wants)
                            .layoutWeight(weight(for: .wants))
                        slab(for: .savingsAndDebts)
                            .layoutWeight(weight(for: .savingsAndDebts))
                    }
                    .layoutWeight(1)
                }
            } else {
                ProportionalStack {
                    needsSlab
                        .layoutWeight(weight(for: .needs))
                    slab(for: .wants)
                        .layoutWeight(weight(for: .wants))
                    slab(for: .savingsAndDebts)
                        .layoutWeight(weight(for: .savingsAndDebts))
                }
            }
        }
    }

    private func weight(for category: BudgetCategory) -> CGFloat {
        CGFloat(max(percentages[category] ?? 0, 1))
    }

    private var needsSlab: some View {
        slab(for: .needs)
            .overlay(alignment: .topTrailing) {
                StickerView(imageName: "Trente Pig Sticker", rotation: .zero)
                    .frame(width: 150)
                    .offset(x: isWide ? -6 : 10, y: isWide ? 10 : -14)
            }
            .zIndex(1)
    }

    private func slab(for category: BudgetCategory) -> some View {
        CategorySlab(
            name: category.shortName,
            examples: category.shortExamples,
            percentage: percentages[category] ?? 0,
            color: category.color
        )
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 560)) {
    CategoryTreemap(percentages: [.needs: 50, .wants: 30, .savingsAndDebts: 20], isWide: false)
        .padding()
}

#Preview("Regular", traits: .fixedLayout(width: 700, height: 480)) {
    CategoryTreemap(percentages: [.needs: 50, .wants: 30, .savingsAndDebts: 20], isWide: true)
        .padding()
}

#Preview("Regular Narrow", traits: .fixedLayout(width: 440, height: 560)) {
    CategoryTreemap(percentages: [.needs: 50, .wants: 30, .savingsAndDebts: 20], isWide: true)
        .padding()
}
