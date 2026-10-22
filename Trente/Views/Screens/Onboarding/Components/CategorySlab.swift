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
        HStack(alignment: .top, spacing: DesignSystem.Spacing.medium.rawValue) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.title3)
                    .bold()
                Text(examples)
                    .font(.subheadline)
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(fraction, format: .percent)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(1)
        }
        .foregroundStyle(color.darken(0.8))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            name: BudgetCategory.needs.name,
            examples: BudgetCategory.needs.shortExamples,
            percentage: 50,
            color: BudgetCategory.needs.color
        )
        CategorySlab(
            name: BudgetCategory.savingsAndDebts.name,
            examples: BudgetCategory.savingsAndDebts.shortExamples,
            percentage: 20,
            color: BudgetCategory.savingsAndDebts.color
        )
        .frame(width: 220)
    }
    .padding()
}
