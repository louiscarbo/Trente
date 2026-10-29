//
//  ExportMonthOption.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

struct ExportMonthOption: Identifiable, Hashable {
    let id: UUID
    let name: String
    let startDate: Date
    let transactionCount: Int

    struct YearGroup: Identifiable, Hashable {
        let year: Int
        let options: [ExportMonthOption]

        var id: Int { year }
    }

    static func groupedByYear(_ options: [ExportMonthOption], calendar: Calendar = .current) -> [YearGroup] {
        let byYear = Dictionary(grouping: options) { option in calendar.component(.year, from: option.startDate) }
        return byYear.keys.sorted(by: >).map { year in
            YearGroup(
                year: year,
                options: (byYear[year] ?? []).sorted { lhs, rhs in lhs.startDate > rhs.startDate }
            )
        }
    }
}

extension ExportMonthOption {
    init(month: Month) {
        self.init(
            id: month.id,
            name: month.name,
            startDate: month.startDate,
            transactionCount: month.transactionGroups.count
        )
    }
}
