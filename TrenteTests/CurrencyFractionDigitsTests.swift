//
//  CurrencyFractionDigitsTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 30/10/2026.
//

import Testing
import Foundation
#if canImport(AppKit)
import AppKit
#endif
@testable import Trente

@MainActor
struct CurrencyFractionDigitsTests {
    private let americanEnglish = Locale(identifier: "en_US")

    @Test("The win-back currencies are available", arguments: ["CLP", "CRC", "MYR", "XPF"])
    func availableCurrency(isoCode: String) {
        #expect(Currencies.currency(for: isoCode) != nil)
    }

    @Test(
        "Onboarding starts in the currency of the region",
        arguments: [("es_CL", "CLP"), ("es_CR", "CRC"), ("ms_MY", "MYR"), ("fr_PF", "XPF")]
    )
    func regionDefault(localeIdentifier: String, isoCode: String) {
        #expect(OnboardingModel.defaultCurrency(for: Locale(identifier: localeIdentifier)).isoCode == isoCode)
    }

    @Test("Fraction digits agree with the system for every available currency")
    func fractionDigitsMatchSystem() {
        for currency in Currencies.availableCurrencies {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency.isoCode
            #expect(currency.fractionDigits == formatter.maximumFractionDigits, "\(currency.isoCode)")
        }
    }

    @Test("Every available currency has its own sample amounts")
    func sampleAmountsCoverEveryCurrency() {
        for currency in Currencies.availableCurrencies {
            #expect(Currency.sampleAmountsByIsoCode[currency.isoCode] != nil, "\(currency.isoCode)")
        }
    }

    @Test("Sample amounts show without hidden decimals")
    func sampleAmountsAreWholeWithoutMinorUnit() {
        for currency in Currencies.availableCurrencies where currency.fractionDigits == 0 {
            #expect(currency.sampleAmounts.rentCents % 100 == 0, "\(currency.isoCode)")
            #expect(currency.sampleAmounts.bakeryCents % 100 == 0, "\(currency.isoCode)")
        }
    }

    @Test("Currencies without a minor unit show whole amounts", arguments: ["CLP", "JPY", "KRW", "XPF"])
    func wholeAmounts(isoCode: String) throws {
        let currency = try #require(Currencies.currency(for: isoCode))

        #expect(currency.fractionDigits == 0)
        #expect(currency.roundFormatter.maximumFractionDigits == 0)
        #expect(!1_234.56.formatted(.amount(isoCode).locale(americanEnglish)).contains("."))
    }

    @Test("Currencies with a minor unit keep two decimals", arguments: ["CRC", "MYR", "EUR", "USD"])
    func decimalAmounts(isoCode: String) throws {
        let currency = try #require(Currencies.currency(for: isoCode))

        #expect(currency.fractionDigits == 2)
        #expect(currency.roundFormatter.maximumFractionDigits == 2)
        #expect(1_234.56.formatted(.amount(isoCode).locale(americanEnglish)).hasSuffix("1,234.56"))
    }

    @Test(
        "Amount text with a decimal separator is rejected when the currency has no minor unit",
        arguments: ["12.", "12.5", ".5"]
    )
    func rejectsDecimalsWithoutMinorUnit(text: String) {
        #expect(!CurrencyTextField.isValidAmountText(text, decimalSeparator: ".", fractionDigits: 0))
    }

    @Test("Whole amount text is accepted for every currency", arguments: [0, 2])
    func acceptsWholeAmounts(fractionDigits: Int) {
        #expect(CurrencyTextField.isValidAmountText("12500", decimalSeparator: ".", fractionDigits: fractionDigits))
        #expect(CurrencyTextField.isValidAmountText("", decimalSeparator: ".", fractionDigits: fractionDigits))
    }

    @Test(
        "Amount text keeps at most two decimals",
        arguments: [("12.", true), ("12.5", true), ("12.50", true), ("12.505", false), ("1.2.3", false)]
    )
    func limitsDecimals(text: String, isValid: Bool) {
        #expect(CurrencyTextField.isValidAmountText(text, decimalSeparator: ".", fractionDigits: 2) == isValid)
    }

    @Test("A stored amount with hidden decimals shows as a whole number", arguments: [(150_000_50, "150000"), (-150_000_50, "-150000")])
    func roundedDisplay(cents: Int, expectedText: String) {
        #expect(CurrencyTextField.amountText(fromCents: cents, fractionDigits: 0, locale: americanEnglish) == expectedText)
    }

    @Test(
        "Showing an amount never changes it",
        arguments: [(150_000_50, 0), (-150_000_50, 0), (2_500_00, 0), (12_50, 2), (-12_34, 2), (0, 2)]
    )
    func displayedTextChangesNothing(cents: Int, fractionDigits: Int) {
        let text = CurrencyTextField.amountText(fromCents: cents, fractionDigits: fractionDigits, locale: americanEnglish)

        #expect(CurrencyTextField.editedCents(from: text, currentCents: cents, fractionDigits: fractionDigits, locale: americanEnglish) == nil)
    }

    @Test(
        "Typing a different amount replaces the stored one and keeps its sign",
        arguments: [
            ("150001", 150_000_50, 0, 150_001_00),
            ("", 150_000_50, 0, 0),
            ("12.5", 10_00, 2, 12_50),
            ("12", -12_50, 2, -12_00)
        ]
    )
    func typedTextChangesAmount(text: String, currentCents: Int, fractionDigits: Int, expectedCents: Int) {
        let editedCents = CurrencyTextField.editedCents(
            from: text,
            currentCents: currentCents,
            fractionDigits: fractionDigits,
            locale: americanEnglish
        )

        #expect(editedCents == expectedCents)
    }

    #if canImport(AppKit)
    @Test("Every currency symbol exists in all its variants")
    func symbolsExist() {
        for currency in Currencies.availableCurrencies {
            let names = [currency.sfSymbolName, currency.sfSymbolGaugeName, currency.sfSymbolRecurrenceName].compactMap(\.self)
            for name in names {
                #expect(NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil, "\(name)")
            }
        }
    }
    #endif
}
