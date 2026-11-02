//
//  WalletAmountParserTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Testing
@testable import Trente

struct WalletAmountParserTests {

    @Test(
        "Parses Wallet amount text into cents",
        arguments: [
            ("0,50 €", 50),
            ("53,74 €", 5374),
            ("1 234,56 €", 123456),
            ("1\u{00A0}234,56 €", 123456),
            ("1\u{202F}234,56 €", 123456),
            ("1.234,56 €", 123456),
            ("1,234.56", 123456),
            ("€5", 500),
            ("5.5", 550),
            ("1,234", 123400),
            ("-4,20 €", 420),
            ("53,74 kr.", 5374),
            ("1.234,56 kr.", 123456),
            ("kr. 53,74", 5374),
            ("50 kr.", 5000),
            ("1 234,56 kr", 123456),
            ("kr 1\u{00A0}234,56", 123456),
            ("¥1,200", 120000),
            ("\u{FFE5}1,200", 120000),
            ("1 234,56 $", 123456)
        ]
    )
    func parsesAmount(text: String, expectedCents: Int) {
        #expect(WalletAmountParser.cents(from: text) == expectedCents)
    }

    @Test("Rejects text without a positive amount", arguments: ["0,00", "abc", "", "€"])
    func rejectsInvalidAmount(text: String) {
        #expect(WalletAmountParser.cents(from: text) == nil)
    }
}
