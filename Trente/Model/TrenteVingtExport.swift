//
//  TrenteVingtExport.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import Foundation

struct TrenteVingtExport: Decodable {
    var monthStartDay: Int
    var months: [Month]
    var recurringTransactions: [RecurringTransaction]

    struct Month: Decodable {
        var id: UUID
        var monthNumber: Int
        var creationDate: Date
        var budget: Double
        var needsPercentage: Double
        var wantsPercentage: Double
        var savingsPercentage: Double
        var currencyCode: String
        var transactions: [Transaction]
    }

    struct Transaction: Decodable {
        var title: String
        var amount: Double
        var date: Date
        var category: Category
    }

    struct RecurringTransaction: Decodable {
        var id: UUID
        var title: String
        var amount: Double
        var category: Category
        var frequency: RecurrenceFrequency
        var day: Int?
        var startingDate: Date?
    }

    enum Category: String, Decodable {
        case needs
        case wants
        case savingsAndDebts
        case income
    }
}

extension TrenteVingtExport {
    var transactionCount: Int {
        months.reduce(0) { $0 + $1.transactions.count }
    }

    static func decode(from data: Data) throws -> TrenteVingtExport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TrenteVingtExport.self, from: data)
    }
}
