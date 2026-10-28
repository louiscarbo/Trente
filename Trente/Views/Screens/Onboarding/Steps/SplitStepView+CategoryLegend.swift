//
//  SplitStepView+CategoryLegend.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

extension SplitStepView {
    struct CategoryLegend: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(BudgetCategory.allCases) { category in
                    HStack(spacing: DesignSystem.Spacing.small.rawValue) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                        Text(category.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(category.shortExamples)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
