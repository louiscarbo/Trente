//
//  SampleDataTests.swift
//  TrenteTests
//

import Testing
@testable import Trente
import Foundation

struct SampleDataTests {

    @Test("Sample transactions fall inside their month")
    func transactionsFallInsideTheirMonth() {
        for monthsAgo in 0..<SampleData.monthCount {
            let month = Month.sample(monthsAgo: monthsAgo)

            for group in month.transactionGroups {
                #expect(group.addedDate >= month.startDate)
                #expect(group.addedDate <= month.endDate().addingTimeInterval(24 * 60 * 60))
            }
        }
    }

    @Test("Current month sample has no future transactions")
    func currentMonthHasNoFutureTransactions() {
        let month = Month.sample(monthsAgo: 0)

        #expect(month.transactionGroups.allSatisfy { $0.addedDate <= .now })
    }

    @Test("Sample transactions are spread over several days")
    func transactionsAreSpreadOverSeveralDays() {
        let month = Month.sample(monthsAgo: 1)
        let distinctDays = Set(month.transactionGroups.map {
            Calendar.current.component(.day, from: $0.addedDate)
        })

        #expect(distinctDays.count > 5)
    }

    @Test("Income and expense groups match entry signs")
    func groupTypesMatchEntrySigns() {
        let month = Month.sample(monthsAgo: 1)

        for group in month.transactionGroups {
            let allPositive = group.entries.allSatisfy { $0.amountCents > 0 }
            #expect((group.type == .income) == allPositive)
        }
    }
}
