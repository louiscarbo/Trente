//
//  WalletAmountParser.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Foundation

enum WalletAmountParser {
    static func cents(from text: String) -> Int? {
        let relevant = text.filter { $0.isASCII && ($0.isNumber || $0 == "." || $0 == ",") }
        guard relevant.contains(where: \.isNumber) else { return nil }

        let wholePart: String
        let fractionPart: String
        if let separatorIndex = relevant.lastIndex(where: { $0 == "." || $0 == "," }) {
            let digitsAfter = relevant[relevant.index(after: separatorIndex)...]
            if digitsAfter.count == 1 || digitsAfter.count == 2 {
                wholePart = relevant[..<separatorIndex].filter(\.isNumber)
                fractionPart = String(digitsAfter)
            } else {
                wholePart = relevant.filter(\.isNumber)
                fractionPart = ""
            }
        } else {
            wholePart = relevant
            fractionPart = ""
        }

        let whole = wholePart.isEmpty ? 0 : Int(wholePart)
        let fraction = Int(fractionPart.padding(toLength: 2, withPad: "0", startingAt: 0))
        guard let whole, let fraction, whole <= (Int.max - 99) / 100 else { return nil }

        let cents = whole * 100 + fraction
        return cents > 0 ? cents : nil
    }
}
