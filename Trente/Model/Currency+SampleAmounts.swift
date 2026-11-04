//
//  Currency+SampleAmounts.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 04/11/2026.
//

import Foundation

struct SampleAmounts: Equatable {
    let rentCents: Int
    let bakeryCents: Int
}

extension Currency {
    var sampleAmounts: SampleAmounts {
        Currency.sampleAmountsByIsoCode[isoCode] ?? Currency.sampleAmountsByIsoCode["EUR"]!
    }

    static let sampleAmountsByIsoCode: [String: SampleAmounts] = [
        "USD": SampleAmounts(rentCents: 1_400_00, bakeryCents: 5_50),
        "EUR": SampleAmounts(rentCents: 800_00, bakeryCents: 4_50),
        "JPY": SampleAmounts(rentCents: 80_000_00, bakeryCents: 450_00),
        "GBP": SampleAmounts(rentCents: 900_00, bakeryCents: 3_80),
        "CNY": SampleAmounts(rentCents: 3_000_00, bakeryCents: 18_00),
        "AUD": SampleAmounts(rentCents: 2_000_00, bakeryCents: 6_50),
        "CAD": SampleAmounts(rentCents: 1_600_00, bakeryCents: 5_50),
        "CHF": SampleAmounts(rentCents: 1_500_00, bakeryCents: 5_80),
        "HKD": SampleAmounts(rentCents: 12_000_00, bakeryCents: 28_00),
        "SGD": SampleAmounts(rentCents: 2_500_00, bakeryCents: 5_20),
        "SEK": SampleAmounts(rentCents: 8_000_00, bakeryCents: 45_00),
        "KRW": SampleAmounts(rentCents: 700_000_00, bakeryCents: 4_500_00),
        "NOK": SampleAmounts(rentCents: 9_000_00, bakeryCents: 55_00),
        "NZD": SampleAmounts(rentCents: 1_800_00, bakeryCents: 6_50),
        "INR": SampleAmounts(rentCents: 15_000_00, bakeryCents: 120_00),
        "MXN": SampleAmounts(rentCents: 8_000_00, bakeryCents: 45_00),
        "TWD": SampleAmounts(rentCents: 15_000_00, bakeryCents: 60_00),
        "ZAR": SampleAmounts(rentCents: 7_000_00, bakeryCents: 35_00),
        "BRL": SampleAmounts(rentCents: 1_800_00, bakeryCents: 15_00),
        "DKK": SampleAmounts(rentCents: 6_000_00, bakeryCents: 40_00),
        "CLP": SampleAmounts(rentCents: 400_000_00, bakeryCents: 2_500_00),
        "CRC": SampleAmounts(rentCents: 300_000_00, bakeryCents: 2_000_00),
        "MYR": SampleAmounts(rentCents: 1_500_00, bakeryCents: 8_50),
        "XPF": SampleAmounts(rentCents: 90_000_00, bakeryCents: 450_00),
        "ARS": SampleAmounts(rentCents: 500_000_00, bakeryCents: 3_000_00),
        "COP": SampleAmounts(rentCents: 1_500_000_00, bakeryCents: 8_000_00),
        "PEN": SampleAmounts(rentCents: 1_500_00, bakeryCents: 8_00),
        "UYU": SampleAmounts(rentCents: 25_000_00, bakeryCents: 120_00),
        "DOP": SampleAmounts(rentCents: 25_000_00, bakeryCents: 150_00),
        "GTQ": SampleAmounts(rentCents: 3_500_00, bakeryCents: 20_00),
        "BOB": SampleAmounts(rentCents: 2_500_00, bakeryCents: 15_00),
        "PYG": SampleAmounts(rentCents: 2_500_000_00, bakeryCents: 15_000_00),
        "HNL": SampleAmounts(rentCents: 8_000_00, bakeryCents: 60_00),
        "NIO": SampleAmounts(rentCents: 10_000_00, bakeryCents: 80_00),
        "VES": SampleAmounts(rentCents: 50_000_00, bakeryCents: 300_00),
        "XOF": SampleAmounts(rentCents: 150_000_00, bakeryCents: 1_000_00),
        "XAF": SampleAmounts(rentCents: 150_000_00, bakeryCents: 1_000_00),
        "MAD": SampleAmounts(rentCents: 4_000_00, bakeryCents: 15_00),
        "AOA": SampleAmounts(rentCents: 200_000_00, bakeryCents: 1_500_00),
        "MZN": SampleAmounts(rentCents: 25_000_00, bakeryCents: 150_00),
        "NGN": SampleAmounts(rentCents: 300_000_00, bakeryCents: 2_500_00),
        "PHP": SampleAmounts(rentCents: 15_000_00, bakeryCents: 80_00)
    ]
}
