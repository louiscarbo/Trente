//
//  CurrencyFormatStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    static func budget(_ currencyCode: String) -> Self {
        .currency(code: currencyCode).precision(.fractionLength(0))
    }

    static func amount(_ currencyCode: String) -> Self {
        .currency(code: currencyCode)
    }
}
