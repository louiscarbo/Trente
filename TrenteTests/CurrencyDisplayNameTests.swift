//
//  CurrencyDisplayNameTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Testing
@testable import Trente
import Foundation

struct CurrencyDisplayNameTests {
    @Test("Every available currency has a capitalized display name")
    func displayNamesAreCapitalized() throws {
        for currency in Currencies.availableCurrencies {
            let firstLetter = try #require(currency.displayName.first)
            #expect(firstLetter.isUppercase, "\(currency.isoCode): \(currency.displayName)")
        }
    }

    @Test("The display name follows the system name, not the stored English name")
    func displayNameComesFromLocale() throws {
        let euro = try #require(Currencies.currency(for: "EUR"))
        let systemName = try #require(Locale.current.localizedString(forCurrencyCode: "EUR"))

        #expect(euro.displayName.lowercased() == systemName.lowercased())
    }
}
