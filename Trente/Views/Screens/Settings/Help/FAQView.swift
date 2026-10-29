//
//  FAQView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct FAQView: View {
    let items: [FAQItem]
    let contactURL: URL?
    let contactAddress: String

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
                            Answer(text: FAQItem.featured.answer)
                        } label: {
                            FeaturedCard(shares: FeaturedCard.fiftyThirtyTwenty)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(Text(FAQItem.featured.question))
                        }
                    }
                }
                sections(for: items.filter { item in item != FAQItem.featured })
            }
            Section {
                ContactPrompt(contactURL: contactURL, contactAddress: contactAddress)
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
                        Answer(text: item.answer)
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

#Preview {
    NavigationStack {
        FAQView(
            items: FAQItem.all,
            contactURL: nil,
            contactAddress: SupportMail.address
        )
    }
}
