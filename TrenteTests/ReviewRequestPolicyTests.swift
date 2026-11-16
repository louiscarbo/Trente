//
//  ReviewRequestPolicyTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct ReviewRequestPolicyTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test(
        "Asks only from the second month, after two weeks of use",
        arguments: [
            (0, 30, false),
            (1, 30, false),
            (2, 30, true),
            (2, 13, false),
            (2, 14, true),
            (5, 60, true)
        ]
    )
    func monthsAndDaysOfUse(monthCount: Int, daysOfUse: Int, expected: Bool) {
        let firstUse = day(2026, 1, 1)
        let now = calendar.date(byAdding: .day, value: daysOfUse, to: firstUse)!

        let shouldRequest = ReviewRequestPolicy.shouldRequest(
            monthCount: monthCount,
            lastRequestedMonthCount: 0,
            transactionCount: 0,
            lastRequestedTransactionCount: 0,
            lastRequestedVersion: "",
            currentVersion: "1.0",
            firstUseDate: firstUse,
            now: now,
            calendar: calendar
        )

        #expect(shouldRequest == expected)
    }

    @Test("Never asks without a first use date")
    func missingFirstUse() {
        let shouldRequest = ReviewRequestPolicy.shouldRequest(
            monthCount: 3,
            lastRequestedMonthCount: 0,
            transactionCount: 0,
            lastRequestedTransactionCount: 0,
            lastRequestedVersion: "",
            currentVersion: "1.0",
            firstUseDate: nil,
            now: day(2026, 6, 1),
            calendar: calendar
        )

        #expect(!shouldRequest)
    }

    @Test(
        "Asks at most once per version and only after a new month",
        arguments: [
            (2, "1.0", 2, "1.0", false),
            (2, "1.0", 3, "1.0", false),
            (2, "1.0", 2, "1.1", false),
            (2, "1.0", 3, "1.1", true),
            (0, "", 2, "1.0", true)
        ]
    )
    func versionAndMonthCount(
        lastRequestedMonthCount: Int,
        lastRequestedVersion: String,
        monthCount: Int,
        currentVersion: String,
        expected: Bool
    ) {
        let shouldRequest = ReviewRequestPolicy.shouldRequest(
            monthCount: monthCount,
            lastRequestedMonthCount: lastRequestedMonthCount,
            transactionCount: 0,
            lastRequestedTransactionCount: 0,
            lastRequestedVersion: lastRequestedVersion,
            currentVersion: currentVersion,
            firstUseDate: day(2026, 1, 1),
            now: day(2026, 6, 1),
            calendar: calendar
        )

        #expect(shouldRequest == expected)
    }

    @Test("Counts calendar days, not 24-hour periods")
    func calendarDays() {
        let shouldRequest = ReviewRequestPolicy.shouldRequest(
            monthCount: 2,
            lastRequestedMonthCount: 0,
            transactionCount: 0,
            lastRequestedTransactionCount: 0,
            lastRequestedVersion: "",
            currentVersion: "1.0",
            firstUseDate: day(2026, 1, 1, hour: 23),
            now: day(2026, 1, 15, hour: 1),
            calendar: calendar
        )

        #expect(shouldRequest)
    }

    @Test(
        "Asks once the tenth transaction is logged, without waiting for a second month or two weeks",
        arguments: [
            (9, 0, false),
            (10, 0, true),
            (25, 0, true),
            (10, 10, false),
            (25, 12, false),
            (10, 9, true)
        ]
    )
    func transactionCount(
        transactionCount: Int,
        lastRequestedTransactionCount: Int,
        expected: Bool
    ) {
        let firstUse = day(2026, 1, 1)

        let shouldRequest = ReviewRequestPolicy.shouldRequest(
            monthCount: 1,
            lastRequestedMonthCount: 0,
            transactionCount: transactionCount,
            lastRequestedTransactionCount: lastRequestedTransactionCount,
            lastRequestedVersion: "",
            currentVersion: "1.2",
            firstUseDate: firstUse,
            now: firstUse,
            calendar: calendar
        )

        #expect(shouldRequest == expected)
    }

    @Test("Never asks twice in one version, whichever trigger comes second")
    func sharedVersionLimit() {
        let shouldRequest = ReviewRequestPolicy.shouldRequest(
            monthCount: 3,
            lastRequestedMonthCount: 2,
            transactionCount: 10,
            lastRequestedTransactionCount: 4,
            lastRequestedVersion: "1.2",
            currentVersion: "1.2",
            firstUseDate: day(2026, 1, 1),
            now: day(2026, 6, 1),
            calendar: calendar
        )

        #expect(!shouldRequest)
    }
}
