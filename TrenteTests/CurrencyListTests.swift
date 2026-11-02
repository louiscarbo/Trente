//
//  CurrencyListTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 02/11/2026.
//

import Testing
import Foundation
@testable import Trente

@MainActor
struct CurrencyListTests {
    private let americanEnglish = Locale(identifier: "en_US")

    @Test(
        "Onboarding starts in the currency of the region",
        arguments: [
            ("es_AR", "ARS"), ("es_CO", "COP"), ("es_PE", "PEN"), ("es_UY", "UYU"), ("es_DO", "DOP"), ("es_GT", "GTQ"),
            ("es_BO", "BOB"), ("es_PY", "PYG"), ("es_HN", "HNL"), ("es_NI", "NIO"), ("es_VE", "VES"), ("fr_SN", "XOF"),
            ("fr_CM", "XAF"), ("fr_MA", "MAD"), ("pt_AO", "AOA"), ("pt_MZ", "MZN"), ("en_NG", "NGN"), ("en_PH", "PHP")
        ]
    )
    func regionDefault(localeIdentifier: String, isoCode: String) {
        #expect(OnboardingModel.defaultCurrency(for: Locale(identifier: localeIdentifier)).isoCode == isoCode)
    }

    @Test("The digital bolívar code resolves to the bolívar")
    func aliasedIsoCode() {
        #expect(Currencies.currency(for: "VED")?.isoCode == "VES")
    }

    @Test("New currencies without a minor unit show whole amounts", arguments: ["COP", "PYG", "XAF", "XOF"])
    func wholeAmounts(isoCode: String) throws {
        let currency = try #require(Currencies.currency(for: isoCode))

        #expect(currency.fractionDigits == 0)
        #expect(!1_234.56.formatted(.amount(isoCode).locale(americanEnglish)).contains("."))
    }

    @Test(
        "Apple Pay reads amounts written with the new symbols",
        arguments: [
            ("25.000,00 Gs.", 2500000),
            ("150.000 Gs.", 15000000),
            ("1.234,50 Bs.", 123450),
            ("Bs.D 1.234,50", 123450),
            ("S/ 12.50", 1250),
            ("RD$1,234.50", 123450)
        ]
    )
    func applePayAmounts(text: String, expectedCents: Int) {
        #expect(WalletAmountParser.cents(from: text) == expectedCents)
    }

    @Test("Every currency has a different ISO code")
    func uniqueIsoCodes() {
        let isoCodes = Currencies.availableCurrencies.map(\.isoCode)

        #expect(Set(isoCodes).count == isoCodes.count)
    }

    @Test("An empty search lists every currency by name")
    func emptySearch() {
        let names = Currencies.matching("  ").map(\.displayName)

        #expect(names.count == Currencies.availableCurrencies.count)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    @Test("Search finds a currency by ISO code in any case", arguments: ["ARS", "ars", " ars "])
    func searchByIsoCode(searchText: String) {
        #expect(Currencies.matching(searchText).contains { $0.isoCode == "ARS" })
    }

    @Test("Search finds a currency by part of its name")
    func searchByName() throws {
        let currency = try #require(Currencies.currency(for: "NGN"))
        let partOfName = String(currency.displayName.prefix(4)).lowercased()

        #expect(Currencies.matching(partOfName).contains(currency))
    }

    @Test("Search returns nothing when no currency matches")
    func searchWithoutMatch() {
        #expect(Currencies.matching("zzzz").isEmpty)
    }
}
