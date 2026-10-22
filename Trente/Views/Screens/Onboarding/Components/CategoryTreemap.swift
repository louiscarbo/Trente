//
//  CategoryTreemap.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct CategoryTreemap: View {
    let percentages: [BudgetCategory: Int]

    @State private var isWide = false

    var body: some View {
        Group {
            if isWide {
                ProportionalStack(axis: .horizontal) {
                    slab(for: .needs)
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
                    ForEach(BudgetCategory.allCases) { category in
                        slab(for: category)
                            .layoutWeight(weight(for: category))
                    }
                }
            }
        }
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width > proxy.size.height
        } action: { newValue in
            isWide = newValue
        }
    }

    private func weight(for category: BudgetCategory) -> CGFloat {
        CGFloat(max(percentages[category] ?? 0, 1))
    }

    private func slab(for category: BudgetCategory) -> some View {
        CategorySlab(
            name: category.name,
            examples: category.shortExamples,
            percentage: percentages[category] ?? 0,
            color: category.color
        )
    }
}

#Preview("Compact", traits: .fixedLayout(width: 390, height: 560)) {
    CategoryTreemap(percentages: [.needs: 50, .wants: 30, .savingsAndDebts: 20])
        .padding()
}

#Preview("Regular", traits: .fixedLayout(width: 700, height: 480)) {
    CategoryTreemap(percentages: [.needs: 50, .wants: 30, .savingsAndDebts: 20])
        .padding()
}
