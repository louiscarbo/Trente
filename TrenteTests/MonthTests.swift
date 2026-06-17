//
//  MonthTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import Testing
@testable import Trente
import Foundation

struct MonthTests {

    @Test("Spent amount")
    func testSpentAmount() {
        let month = Month(
            startDate: .now,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )

        // Add expense groups with entries
        let groceries = TransactionGroup(
            title: "Groceries",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        groceries.entries = [
            TransactionEntry(amountCents: -100_00, category: .needs, group: groceries)
        ]

        let rent = TransactionGroup(
            title: "Rent",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        rent.entries = [
            TransactionEntry(amountCents: -400_00, category: .needs, group: rent)
        ]

        month.transactionGroups = [groceries, rent]

        #expect(month.negativeSpentAmount == -500.0)
    }

    @Test("Remaining amount")
    func testRemainingAmount() {
        let month = Month(
            startDate: .now,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )

        // Income group
        let salary = TransactionGroup(
            title: "Salary",
            type: .income,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        salary.entries = [
            TransactionEntry(amountCents: 1000_00, category: .needs, group: salary)
        ]

        // Expenses
        let mall = TransactionGroup(
            title: "Mall",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        mall.entries = [
            TransactionEntry(amountCents: -100_00, category: .needs, group: mall)
        ]

        let rent = TransactionGroup(
            title: "Rent",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        rent.entries = [
            TransactionEntry(amountCents: -400_00, category: .needs, group: rent)
        ]

        month.transactionGroups = [salary, mall, rent]

        #expect(month.remainingAmount == 500.0)
    }

    @Test("Overspent true")
    func testOverSpentTrue() {
        let month = Month(
            startDate: .now,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )

        let groceries = TransactionGroup(
            title: "Groceries",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        groceries.entries = [
            TransactionEntry(amountCents: -100_00, category: .needs, group: groceries)
        ]

        month.transactionGroups = [groceries]

        #expect(month.overSpent == true)
    }

    @Test("Overspent false")
    func testOverSpentFalse() {
        let month = Month(
            startDate: .now,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )

        let salary = TransactionGroup(
            title: "Salary",
            type: .income,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        salary.entries = [
            TransactionEntry(amountCents: 2000_00, category: .needs, group: salary)
        ]

        let groceries = TransactionGroup(
            title: "Groceries",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        groceries.entries = [
            TransactionEntry(amountCents: -100_00, category: .needs, group: groceries)
        ]

        month.transactionGroups = [salary, groceries]

        #expect(month.overSpent == false)
    }
    
    @Test("End date of month 1")
    func endDate1() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 4))!
        let expectedEndDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 3))! // Leap year

        let month = Month(
            startDate: startDate,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )

        // When
        let endDate = month.endDate()

        // Then
        #expect(endDate == expectedEndDate)
    }
    
    @Test("End date of month 2")
    func endDate2() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 6))!
        let expectedEndDate = calendar.date(from: DateComponents(year: 2024, month: 7, day: 5))!

        let month = Month(
            startDate: startDate,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )

        // When
        let endDate = month.endDate()

        // Then
        #expect(endDate == expectedEndDate)
    }
    
    @Test("Remaining amount in category")
    func testRemainingAmountInCategory() {
        let month = Month(
            startDate: .now,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )

        // Income group
        let salary = TransactionGroup(
            title: "Salary",
            type: .income,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        salary.entries = [
            TransactionEntry(amountCents: 1000_00, category: .needs, group: salary)
        ]

        // Expenses
        let mall = TransactionGroup(
            title: "Mall",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        mall.entries = [
            TransactionEntry(amountCents: -100_00, category: .needs, group: mall)
        ]

        let rent = TransactionGroup(
            title: "Rent",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        rent.entries = [
            TransactionEntry(amountCents: -400_00, category: .needs, group: rent)
        ]

        month.transactionGroups = [salary, mall, rent]

        #expect(month.remainingAmount(for: .needs) == 500.0)
    }

}
