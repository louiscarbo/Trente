//
//  CategorySlab.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct CategorySlab: View {
    let name: String
    let examples: String
    let percentage: Int
    let color: Color

    private var fraction: Double {
        Double(percentage) / 100
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: DesignSystem.Spacing.medium.rawValue) {
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.title2)
                    .bold()
                Text(examples)
                    .font(.footnote)
                    .opacity(0.75)
            }
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(fraction, format: .percent)
                .font(.system(size: 72, weight: .heavy))
                .tracking(-2.16)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .layoutPriority(1)
        }
        .foregroundStyle(color.darken(0.8))
        .padding(.top, 12)
        .padding(.bottom, 6)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(color, in: RoundedRectangle(cornerRadius: .large))
        .overlay {
            RoundedRectangle(cornerRadius: .large)
                .strokeBorder(color.darken(0.1), lineWidth: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(name), \(fraction.formatted(.percent))"))
    }
}

#Preview {
    VStack {
        CategorySlab(
            name: BudgetCategory.needs.shortName,
            examples: BudgetCategory.needs.shortExamples,
            percentage: 50,
            color: BudgetCategory.needs.color
        )
        CategorySlab(
            name: BudgetCategory.savingsAndDebts.shortName,
            examples: BudgetCategory.savingsAndDebts.shortExamples,
            percentage: 20,
            color: BudgetCategory.savingsAndDebts.color
        )
        .frame(width: 220)
    }
    .padding()
}
