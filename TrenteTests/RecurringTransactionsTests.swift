//
//  RecurringTransactionsTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import Testing
@testable import Trente
import Foundation

struct RecurringTransactionRuleTests {
    
    @Test("Weekly recurrence")
    func weeklyRecurrence() {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let eur = Currencies.currency(for: "EUR")!
        // Rule starts on Wednesday April 2, 2025 and recurs weekly
        let ruleStart = calendar.date(from: DateComponents(year: 2025, month: 4, day: 2))!
        let rule = RecurringTransactionRule(
            title: "Subscription",
            frequency: .weekly,
            startDate: ruleStart,
            autoConfirm: true,
            repartition: [.wants: 1000]
        )
        
        // Month = April 2025
        let monthStart = calendar.date(from: DateComponents(year: 2025, month: 4, day: 1))!
        let month = Month(
            startDate: monthStart,
            currency: eur,
            categoryRepartition: [:]
        )
        
        // When
        let instances = rule.createRecurringInstances(for: month)
        
        // Then: expect Wednesdays 2, 9, 16, 23, 30
        let days = instances.map { calendar.component(.day, from: $0.date) }
        #expect(days == [2, 9, 16, 23, 30])
        #expect(instances.count == 5)
        #expect(instances.allSatisfy { $0.confirmed == rule.autoConfirm })
    }
    
    @Test("Monthly recurrence")
    func monthlyRecurrence() {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let eur = Currencies.currency(for: "EUR")!
        // Rule on the 15th of each month
        let ruleStart = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let rule = RecurringTransactionRule(
            title: "Pay Rent",
            frequency: .monthly,
            startDate: ruleStart,
            autoConfirm: false,
            repartition: [.needs: 50000]
        )
        
        // Month = February 2025
        let monthStart = calendar.date(from: DateComponents(year: 2025, month: 2, day: 1))!
        let month = Month(
            startDate: monthStart,
            currency: eur,
            categoryRepartition: [:]
        )
        
        // When
        let instances = rule.createRecurringInstances(for: month)
        
        // Then: exactly one on Feb 15, 2025
        #expect(instances.count == 1)
        let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        #expect(instances.first?.date == expectedDate)
        #expect(instances.first?.confirmed == false)
    }
    
    @Test("Yearly recurrence")
    func yearlyRecurrence() {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let eur = Currencies.currency(for: "EUR")!
        // Rule on December 25 each year since 2020
        let ruleStart = calendar.date(from: DateComponents(year: 2020, month: 12, day: 25))!
        let rule = RecurringTransactionRule(
            title: "Holiday",
            frequency: .yearly,
            startDate: ruleStart,
            autoConfirm: true,
            repartition: [.savingsAndDebts: 0]
        )
        
        // Month = December 2023
        let monthStart = calendar.date(from: DateComponents(year: 2023, month: 12, day: 1))!
        let month = Month(
            startDate: monthStart,
            currency: eur,
            categoryRepartition: [:]
        )
        
        // When
        let instances = rule.createRecurringInstances(for: month)
        
        // Then: one on Dec 25, 2023
        #expect(instances.count == 1)
        let expectedDate = calendar.date(from: DateComponents(year: 2023, month: 12, day: 25))!
        #expect(instances[0].date == expectedDate)
        #expect(instances[0].confirmed == rule.autoConfirm)
    }
    
    @Test("No occurrences if outside window")
    func noOccurrences() {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let eur = Currencies.currency(for: "EUR")!
        // Rule starts June 1, 2025
        let ruleStart = calendar.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let rule = RecurringTransactionRule(
            title: "Future Payment",
            frequency: .monthly,
            startDate: ruleStart,
            repartition: [.wants: 0]
        )
        
        // Month = May 2025
        let monthStart = calendar.date(from: DateComponents(year: 2025, month: 5, day: 1))!
        let month = Month(
            startDate: monthStart,
            currency: eur,
            categoryRepartition: [:]
        )
        
        // When
        let instances = rule.createRecurringInstances(for: month)
        
        // Then: no instances
        #expect(instances.isEmpty)
    }
}
