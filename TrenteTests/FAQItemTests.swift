//
//  FAQItemTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct FAQItemTests {

    @Test("Every question has its own identifier")
    func uniqueIdentifiers() {
        let identifiers = FAQItem.all.map(\.id)

        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test("Without an iPhone, the Apple Pay question is left out")
    func itemsWithoutPhone() {
        let identifiers = FAQItem.items(isPhone: false).map(\.id)

        #expect(!identifiers.contains("applePay"))
        #expect(identifiers.count == FAQItem.all.count - 1)
    }

    @Test("On iPhone, every question is shown")
    func itemsOnPhone() {
        #expect(FAQItem.items(isPhone: true) == FAQItem.all)
    }

    @Test("Every question and answer has text")
    func nonEmptyText() {
        for item in FAQItem.all {
            #expect(!String(localized: item.question).isEmpty)
            #expect(!String(localized: item.answer).isEmpty)
        }
    }

    @Test("Every topic has at least one question")
    func everyTopicHasQuestions() {
        let topics = FAQSection.sections(for: FAQItem.all).map(\.topic)

        #expect(topics == FAQTopic.allCases)
    }

    @Test("The featured question is in the list, so search still finds it")
    func featuredIsListed() {
        #expect(FAQItem.all.contains(FAQItem.featured))
    }

    @Test("Sections follow the topic order and leave out empty topics")
    func sectionsFollowTopicOrder() {
        let items = [
            item("rent", topic: .recurring),
            item("months", topic: .budgetBasics),
            item("salary", topic: .recurring)
        ]

        let sections = FAQSection.sections(for: items)

        #expect(sections.map(\.topic) == [.budgetBasics, .recurring])
        #expect(sections.last?.items.map(\.id) == ["rent", "salary"])
    }

    @Test("An empty search shows every question")
    func emptySearchKeepsEverything() {
        let items = [item("rent"), item("salary")]

        #expect(FAQItem.matching("   ", in: items) == items)
    }

    @Test("Search ignores case and accents")
    func searchIgnoresCaseAndAccents() {
        let items = [
            item("cafe", question: "Café budget"),
            item("rent", question: "Rent")
        ]

        #expect(FAQItem.matching("CAFE", in: items).map(\.id) == ["cafe"])
    }

    @Test("Every word must appear in the question or the answer")
    func searchNeedsEveryWord() {
        let items = [item("rent", question: "What is rent?", answer: "Paid monthly")]

        #expect(FAQItem.matching("rent monthly", in: items).map(\.id) == ["rent"])
        #expect(FAQItem.matching("rent yearly", in: items).isEmpty)
    }

    private func item(
        _ id: String,
        topic: FAQTopic = .budgetBasics,
        question: String = "Question",
        answer: String = "Answer"
    ) -> FAQItem {
        FAQItem(
            id: id,
            topic: topic,
            question: LocalizedStringResource(stringLiteral: question),
            answer: LocalizedStringResource(stringLiteral: answer)
        )
    }
}
