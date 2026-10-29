//
//  WalletIntakeAllowanceTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct WalletIntakeAllowanceTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeAllowance() -> WalletIntakeAllowance {
        WalletIntakeAllowance(
            defaults: UserDefaults(suiteName: "WalletIntakeAllowanceTests.\(UUID().uuidString)")!,
            calendar: calendar
        )
    }

    private func date(month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    @Test("Starts the month with no Apple Pay logs")
    func startsEmpty() {
        #expect(makeAllowance().count(on: date(month: 10, day: 29)) == 0)
    }

    @Test("Counts every recorded log within the same month")
    func countsWithinMonth() {
        let allowance = makeAllowance()

        allowance.recordIntake(on: date(month: 10, day: 1))
        allowance.recordIntake(on: date(month: 10, day: 15))
        allowance.recordIntake(on: date(month: 10, day: 31))

        #expect(allowance.count(on: date(month: 10, day: 31)) == 3)
    }

    @Test("A new month starts the count over")
    func resetsEachMonth() {
        let allowance = makeAllowance()
        allowance.setCount(WalletIntakeAllowance.freeMonthlyLimit, on: date(month: 10, day: 31))

        #expect(allowance.count(on: date(month: 11, day: 1)) == 0)
        allowance.recordIntake(on: date(month: 11, day: 1))
        #expect(allowance.count(on: date(month: 11, day: 2)) == 1)
    }

    @Test("Free users can log until the monthly limit")
    func allowsUntilLimit() {
        let allowance = makeAllowance()
        let today = date(month: 10, day: 29)

        allowance.setCount(WalletIntakeAllowance.freeMonthlyLimit - 1, on: today)
        #expect(allowance.allowsIntake(on: today, isTrentePlusSubscribed: false))

        allowance.recordIntake(on: today)
        #expect(!allowance.allowsIntake(on: today, isTrentePlusSubscribed: false))
    }

    @Test("Trente+ logs past the monthly limit")
    func trentePlusIsUnlimited() {
        let allowance = makeAllowance()
        let today = date(month: 10, day: 29)
        allowance.setCount(WalletIntakeAllowance.freeMonthlyLimit * 3, on: today)

        #expect(allowance.allowsIntake(on: today, isTrentePlusSubscribed: true))
    }

    @Test("Cancelling a log gives it back, never below zero")
    func cancelGivesLogBack() {
        let allowance = makeAllowance()
        let today = date(month: 10, day: 29)

        allowance.recordIntake(on: today)
        allowance.cancelIntake(on: today)
        allowance.cancelIntake(on: today)

        #expect(allowance.count(on: today) == 0)
    }
}
