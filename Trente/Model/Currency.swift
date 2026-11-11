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
    var displayName: String {
        guard let systemName = Locale.current.localizedString(forCurrencyCode: isoCode) else { return localizedName }
        return systemName.prefix(1).localizedUppercase + systemName.dropFirst()
    }
}

extension Currency {
    private static let isoCodesWithoutMinorUnit: Set<String> = ["CLP", "COP", "JPY", "KRW", "PYG", "XAF", "XOF", "XPF"]

    var fractionDigits: Int {
        Currency.isoCodesWithoutMinorUnit.contains(isoCode) ? 0 : 2
    }
}

extension Currency {
    nonisolated(unsafe) private static var formatterCache: [String: NumberFormatter] = [:]
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
        formatter.currencySymbol = narrowSymbol
        formatter.maximumFractionDigits = fractionDigits
        
        Currency.formatterCache[isoCode] = formatter
        return formatter
    }

    private var narrowSymbol: String {
        0.0.formatted(.budget(isoCode)).filter { !$0.isNumber && !$0.isWhitespace }
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
extension Currency {
    static let fallback = Currency(isoCode: "EUR", symbol: "€", sfSymbolName: "eurosign", localizedName: "Euro")
}

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
        Currency(isoCode: "DKK", symbol: "kr",  sfSymbolName: "danishkronesign",         localizedName: "Danish Krone"),
        Currency(isoCode: "CLP", symbol: "CL$", sfSymbolName: "dollarsign",              localizedName: "Chilean Peso"),
        Currency(isoCode: "CRC", symbol: "₡",   sfSymbolName: "coloncurrencysign",       localizedName: "Costa Rican Colón"),
        Currency(isoCode: "MYR", symbol: "RM",  sfSymbolName: "malaysianringgitsign",    localizedName: "Malaysian Ringgit"),
        Currency(isoCode: "XPF", symbol: "F",   sfSymbolName: "francsign",               localizedName: "CFP Franc"),
        Currency(isoCode: "ARS", symbol: "AR$", sfSymbolName: "dollarsign",              localizedName: "Argentine Peso"),
        Currency(isoCode: "COP", symbol: "CO$", sfSymbolName: "dollarsign",              localizedName: "Colombian Peso"),
        Currency(isoCode: "PEN", symbol: "S/",  sfSymbolName: "peruviansolessign",       localizedName: "Peruvian Sol"),
        Currency(isoCode: "UYU", symbol: "$U",  sfSymbolName: "dollarsign",              localizedName: "Uruguayan Peso"),
        Currency(isoCode: "DOP", symbol: "RD$", sfSymbolName: "dollarsign",              localizedName: "Dominican Peso"),
        Currency(isoCode: "GTQ", symbol: "Q",   sfSymbolName: nil,                       localizedName: "Guatemalan Quetzal"),
        Currency(isoCode: "BOB", symbol: "Bs",  sfSymbolName: nil,                       localizedName: "Bolivian Boliviano"),
        Currency(isoCode: "PYG", symbol: "₲",   sfSymbolName: "guaranisign",             localizedName: "Paraguayan Guarani"),
        Currency(isoCode: "HNL", symbol: "L",   sfSymbolName: nil,                       localizedName: "Honduran Lempira"),
        Currency(isoCode: "NIO", symbol: "C$",  sfSymbolName: "dollarsign",              localizedName: "Nicaraguan Córdoba"),
        Currency(isoCode: "VES", symbol: "Bs.", sfSymbolName: nil,                       localizedName: "Venezuelan Bolívar"),
        Currency(isoCode: "XOF", symbol: "CFA", sfSymbolName: "francsign",               localizedName: "West African CFA Franc"),
        Currency(isoCode: "XAF", symbol: "CFA", sfSymbolName: "francsign",               localizedName: "Central African CFA Franc"),
        Currency(isoCode: "MAD", symbol: "DH",  sfSymbolName: nil,                       localizedName: "Moroccan Dirham"),
        Currency(isoCode: "AOA", symbol: "Kz",  sfSymbolName: nil,                       localizedName: "Angolan Kwanza"),
        Currency(isoCode: "MZN", symbol: "MT",  sfSymbolName: nil,                       localizedName: "Mozambican Metical"),
        Currency(isoCode: "NGN", symbol: "₦",   sfSymbolName: "nairasign",               localizedName: "Nigerian Naira"),
        Currency(isoCode: "PHP", symbol: "₱",   sfSymbolName: "pesosign",                localizedName: "Philippine Peso")
    ]

    private static let isoCodeAliases = ["VED": "VES"]

    static func currency(for isoCode: String) -> Currency? {
        let canonicalIsoCode = isoCodeAliases[isoCode] ?? isoCode
        return availableCurrencies.first { $0.isoCode == canonicalIsoCode }
    }

    static func matching(_ searchText: String) -> [Currency] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return availableCurrencies
            .filter { query.isEmpty || $0.displayName.localizedStandardContains(query) || $0.isoCode.localizedStandardContains(query) }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }
}
// swiftlint:enable comma
