//
//  TrenteVingtImportSummary.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import Foundation

struct TrenteVingtImportSummary: Equatable {
    var monthCount = 0
    var transactionCount = 0
    var recurringTransactionCount = 0
    var skippedMonthCount = 0
    var skippedTransactionCount = 0

    var isEmpty: Bool {
        monthCount == 0 && recurringTransactionCount == 0
    }

    var skipNote: String? {
        guard skippedMonthCount > 0 else { return nil }
        return String(localized: """
            Months not imported: \(skippedMonthCount). Transactions not imported: \(skippedTransactionCount). \
            Trente already has a month on those dates, or doesn't support their currency.
            """)
    }
}
