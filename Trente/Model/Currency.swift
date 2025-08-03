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
        guard let name = sfSymbolName else { return "gauge.chart.leftthird.topthird.rightthird" }
        return "\(name).gauge.chart.leftthird.topthird.rightthird"
    }

    /// The name of the SF Symbol corresponding to the currency symbol inside a circle arrow to represent recurrence.
    var sfSymbolRecurrenceName: String {
        guard let name = sfSymbolName else { return "arrow.trianglehead.counterclockwise.rotate.90" }
        return "\(name).arrow.trianglehead.counterclockwise.rotate.90"
    }
}

// swiftlint:disable comma
struct Currencies {
    static let availableCurrencies: [Currency] = [
        Currency(isoCode: "USD", symbol: "$",   sfSymbolName: "dollarsign",              localizedName: "US Dollar"),
        Currency(isoCode: "EUR", symbol: "€",   sfSymbolName: "eurosign",                localizedName: "Euro"),
        Currency(isoCode: "JPY", symbol: "¥",   sfSymbolName: "yensign",                 localizedName: "Japanese Yen"),
        Currency(isoCode: "GBP", symbol: "£",   sfSymbolName: "sterlingsign",            localizedName: "Pound Sterling"),
        Currency(isoCode: "CNY", symbol: "¥",   sfSymbolName: "chineseyuanrenminbisign", localizedName: "Chinese Yuan"),
        Currency(isoCode: "AUD", symbol: "A$",  sfSymbolName: "australiandollarsign",    localizedName: "Australian Dollar"),
        Currency(isoCode: "CAD", symbol: "C$",  sfSymbolName: "dollarsign",              localizedName: "Canadian Dollar"),
        Currency(isoCode: "CHF", symbol: "CHF", sfSymbolName: "francsign",               localizedName: "Swiss Franc"),
        Currency(isoCode: "HKD", symbol: "HK$", sfSymbolName: "dollarsign",              localizedName: "Hong Kong Dollar"),
        Currency(isoCode: "SGD", symbol: "S$",  sfSymbolName: "singaporedollarsign",     localizedName: "Singapore Dollar"),
        Currency(isoCode: "SEK", symbol: "kr",  sfSymbolName: "swedishkronasign",        localizedName: "Swedish Krona"),
        Currency(isoCode: "KRW", symbol: "₩",   sfSymbolName: "wonsign",                 localizedName: "South Korean Won"),
        Currency(isoCode: "NOK", symbol: "kr",  sfSymbolName: "norwegiankronesign",      localizedName: "Norwegian Krone"),
        Currency(isoCode: "NZD", symbol: "NZ$", sfSymbolName: "dollarsign",              localizedName: "New Zealand Dollar"),
        Currency(isoCode: "INR", symbol: "₹",   sfSymbolName: "indianrupeesign",         localizedName: "Indian Rupee"),
        Currency(isoCode: "MXN", symbol: "MX$", sfSymbolName: "pesosign",                localizedName: "Mexican Peso"),
        Currency(isoCode: "TWD", symbol: "NT$", sfSymbolName: "dollarsign",              localizedName: "New Taiwan Dollar"),
        Currency(isoCode: "ZAR", symbol: "R",   sfSymbolName: nil,                       localizedName: "South African Rand"),
        Currency(isoCode: "BRL", symbol: "R$",  sfSymbolName: "brazilianrealsign",       localizedName: "Brazilian Real"),
        Currency(isoCode: "DKK", symbol: "kr",  sfSymbolName: "danishkronesign",         localizedName: "Danish Krone")
    ]

    static func currency(for isoCode: String) -> Currency? {
        availableCurrencies.first { $0.isoCode == isoCode }
    }
}
// swiftlint:enable comma
