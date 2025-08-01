//
//  Currency.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation

struct Currency: Codable, Hashable, Identifiable {
    var id: String { isoCode }
    let isoCode: String
    var symbol: String
    var sfSymbolName: String?
    var localizedName: String
}

extension Currency {
    private static var formatterCache: [String: NumberFormatter] = [:]
    private static let cacheLock = NSLock()
    
    var roundFormatter: NumberFormatter {
        Currency.cacheLock.lock()
        defer { Currency.cacheLock.unlock() }
        
        if let cachedFormatter = Currency.formatterCache[isoCode] {
            return cachedFormatter
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = isoCode
        formatter.locale = .autoupdatingCurrent
        formatter.maximumFractionDigits = 2
        
        Currency.formatterCache[isoCode] = formatter
        return formatter
    }
}

extension Currency {
    /// The name of the SF Symbol corresponding to the currency symbol inside a gauge with two sections.
    var sfSymbolGaugeName: String {
        sfSymbolName.map { "\($0).gauge.chart.leftthird.topthird.rightthird" } ?? ""
    }
    
    /// The name of the SF Symbol corresponding to the currency symbol inside a circle arrow to represent recurrence.
    var sfSymbolRecurrenceName: String {
        sfSymbolName.map { "\($0).arrow.trianglehead.counterclockwise.rotate.90" } ?? ""
    }
}

struct Currencies {
    static let availableCurrencies: [Currency] = [
        Currency(isoCode: "USD", symbol: "$", sfSymbolName: "dollarsign", localizedName: "US Dollar"),
        Currency(isoCode: "EUR", symbol: "€", sfSymbolName: "eurosign", localizedName: "Euro"),
        Currency(isoCode: "JPY", symbol: "¥", sfSymbolName: "yensign", localizedName: "Japanese Yen")
    ]
    
    static func currency(for isoCode: String) -> Currency? {
        availableCurrencies.first { $0.isoCode == isoCode }
    }
}
