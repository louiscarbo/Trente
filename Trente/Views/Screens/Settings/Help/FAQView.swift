//
//  FAQView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct FAQView: View {
    let items: [FAQItem]

    @State private var searchText = ""

    var body: some View {
        Form {
            if isSearching {
                let results = FAQItem.matching(searchText, in: items)
                if results.isEmpty {
                    ContentUnavailableView.search
                } else {
                    sections(for: results)
                }
            } else {
                if items.contains(FAQItem.featured) {
                    Section {
                        DisclosureGroup {
                            FAQAnswer(text: FAQItem.featured.answer)
                        } label: {
                            FAQFeaturedCard(shares: FAQFeaturedCard.fiftyThirtyTwenty)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(Text(FAQItem.featured.question))
                        }
                    }
                }
                sections(for: items.filter { item in item != FAQItem.featured })
            }
        }
        .formStyle(.grouped)
        .searchable(text: $searchText, prompt: "Search questions")
        .navigationTitle("Frequently Asked Questions")
        .inlineNavigationBarTitleDisplayMode()
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func sections(for items: [FAQItem]) -> some View {
        ForEach(FAQSection.sections(for: items)) { section in
            Section {
                ForEach(section.items) { item in
                    DisclosureGroup {
                        FAQAnswer(text: item.answer)
                    } label: {
                        Text(item.question)
                    }
                }
            } header: {
                Text(section.topic.title)
            }
        }
    }
}

struct FAQFeaturedCard: View {
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
        GeometryReader { proxy in
            let total = max(1, shares.values.reduce(0, +))
            let width = proxy.size.width - barSpacing * CGFloat(BudgetCategory.allCases.count - 1)
            HStack(spacing: barSpacing) {
                ForEach(BudgetCategory.allCases) { category in
                    category.color
                        .frame(width: max(0, width) * CGFloat(shares[category] ?? 0) / CGFloat(total))
                }
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

struct FAQAnswer: View {
    let text: LocalizedStringResource

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
    }
}

#Preview {
    NavigationStack {
        FAQView(items: FAQItem.all)
    }
}
