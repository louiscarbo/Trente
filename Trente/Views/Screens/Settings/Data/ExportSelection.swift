//
//  ExportSelection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Foundation

struct ExportSelection {
    let options: [ExportMonthOption]
    let excludedMonthIDs: Set<UUID>
    let monthIDsWithImages: Set<UUID>
    let format: TransactionCSVFormat

    var selectedOptions: [ExportMonthOption] {
        options.filter { option in !excludedMonthIDs.contains(option.id) }
    }

    var includesEveryMonth: Bool {
        excludedMonthIDs.isEmpty
    }

    var transactionCount: Int {
        selectedOptions.reduce(0) { total, option in total + option.transactionCount }
    }

    var file: TransactionsCSVFile {
        let selectedOptions = selectedOptions
        return TransactionsCSVFile(
            monthIDs: selectedOptions.map(\.id),
            fileName: TransactionsCSVFile.fileName(
                forMonthsStartingOn: selectedOptions.map(\.startDate),
                includesEveryMonth: includesEveryMonth
            ),
            format: format,
            hasImages: selectedOptions.contains { option in monthIDsWithImages.contains(option.id) }
        )
    }
}
