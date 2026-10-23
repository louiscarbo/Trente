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
}
