//
//  BudgetRingsCard+Legend.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

extension BudgetRingsCard {
    struct Legend: View {
        var body: some View {
            HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                ForEach(BudgetCategory.allCases) { category in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)
                        Text(category.shortName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.footnote)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(minHeight: 18)
        }
    }
}
