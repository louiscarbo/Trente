//
//  TrentePlusBenefitTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct TrentePlusBenefitTests {

    @Test("Every benefit has its own identifier")
    func uniqueIdentifiers() {
        let identifiers = TrentePlusBenefit.all.map(\.id)

        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test("Automatic recurring transactions come first, supporting the developer comes last")
    func order() {
        #expect(TrentePlusBenefit.all.first?.id == "automaticRecurring")
        #expect(TrentePlusBenefit.all.last?.id == "supportIndieDeveloper")
    }

    @Test("Every benefit has a title and a detail")
    func nonEmptyText() {
        for benefit in TrentePlusBenefit.all {
            #expect(!String(localized: benefit.title).isEmpty)
            #expect(!String(localized: benefit.detail).isEmpty)
        }
    }
}
