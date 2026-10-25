//
//  FAQSearch.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import Foundation

extension FAQItem {
    static func items(isPhone: Bool) -> [FAQItem] {
        isPhone ? all : all.filter { item in !item.isPhoneOnly }
    }

    static func matching(_ query: String, in items: [FAQItem]) -> [FAQItem] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return items }
        return items.filter { item in
            let text = String(localized: item.question) + " " + String(localized: item.answer)
            return words.allSatisfy { word in text.localizedStandardContains(word) }
        }
    }
}

extension FAQSection {
    static func sections(for items: [FAQItem]) -> [FAQSection] {
        FAQTopic.allCases.compactMap { topic in
            let topicItems = items.filter { item in item.topic == topic }
            return topicItems.isEmpty ? nil : FAQSection(topic: topic, items: topicItems)
        }
    }
}
