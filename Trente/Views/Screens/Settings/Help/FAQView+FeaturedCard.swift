//
//  FAQView+FeaturedCard.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

extension FAQView {
    struct FeaturedCard: View {
        static let fiftyThirtyTwenty: [BudgetCategory: Int] = [.needs: 50, .wants: 30, .savingsAndDebts: 20]

        let shares: [BudgetCategory: Int]

        private let barSpacing: CGFloat = 2

        var body: some View {
            VStack(alignment: .leading, spacing: .small) {
                Text("New to Trente?")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text("The 50/30/20 rule in 30 seconds")
                    .font(.headline)
                bar
                HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                    ForEach(BudgetCategory.allCases) { category in
                        Label {
                            Text("\(category.shortName) \(percentage(for: category))")
                        } icon: {
                            Circle()
                                .fill(category.color)
                                .frame(width: 8, height: 8)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                Text("Split your take-home income into Needs, Wants and Savings and Debts. Trente sorts every transaction into one of them.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, DesignSystem.Spacing.small.rawValue)
        }

        private var bar: some View {
            ProportionalStack(axis: .horizontal, spacing: barSpacing) {
                ForEach(BudgetCategory.allCases) { category in
                    category.color
                        .layoutWeight(CGFloat(shares[category] ?? 0))
                }
            }
            .frame(height: 10)
            .clipShape(.capsule)
            .accessibilityHidden(true)
        }

        private func percentage(for category: BudgetCategory) -> String {
            (Double(shares[category] ?? 0) / 100).formatted(.percent)
        }
    }
}
