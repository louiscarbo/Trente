//
//  RecurringTransactionRuleDescriptionTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Testing
@testable import Trente
import Foundation

struct RecurringTransactionRuleDescriptionTests {
    @Test("A yearly rule is described with its day of the month")
    func yearlyDescriptionUsesDayOfMonth() throws {
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 27)))
        let rule = RecurringTransactionRule(
            title: "Insurance",
            frequency: .yearly,
            startDate: startDate,
            repartition: [.needs: -300_00],
            createdAt: startDate
        )

        #expect(rule.frequencyDescription.contains("27"))
        #expect(rule.frequencyDescription.contains(startDate.formatted(.dateTime.month(.wide))))
    }
}
