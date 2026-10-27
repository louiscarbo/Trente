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

        #expect(month.spentAmount(in: .all) == 500.0)
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
    
    @Test("Figures for overall and category scopes")
    func figuresInScope() {
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
            TransactionEntry(amountCents: 600_00, category: .needs, group: salary),
            TransactionEntry(amountCents: 400_00, category: .wants, group: salary)
        ]

        let groceries = TransactionGroup(
            title: "Groceries",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        groceries.entries = [
            TransactionEntry(amountCents: -100_00, category: .needs, group: groceries),
            TransactionEntry(amountCents: -500_00, category: .wants, group: groceries)
        ]

        month.transactionGroups = [salary, groceries]

        #expect(month.figures(in: .all) == BudgetFigures(spent: 600, income: 1000, remaining: 400))
        #expect(month.figures(in: .category(.needs)) == BudgetFigures(spent: 100, income: 600, remaining: 500))
        #expect(month.figures(in: .category(.wants)) == BudgetFigures(spent: 500, income: 400, remaining: -100))
        #expect(month.figures(in: .category(.wants)).isOverspent)
        #expect(month.figures(in: .category(.savingsAndDebts)) == BudgetFigures(spent: 0, income: 0, remaining: 0))
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
    
    @Test("End date of a month starting on the 31st stays before the next month")
    func endDateOnThirtyFirst() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let expectedEndDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 27))!

        let month = Month(
            startDate: startDate,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
        )

        #expect(month.endDate() == expectedEndDate)
        #expect(month.dateInterval.end == calendar.date(byAdding: .day, value: 1, to: expectedEndDate))
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

    @Test("Scoped amounts: total matches sum of categories, savings included")
    func testScopedAmounts() {
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
            TransactionEntry(amountCents: 1000_00, category: .needs, group: salary),
            TransactionEntry(amountCents: 600_00, category: .wants, group: salary),
            TransactionEntry(amountCents: 400_00, category: .savingsAndDebts, group: salary)
        ]

        let spending = TransactionGroup(
            title: "Spending",
            type: .expense,
            month: month,
            note: nil,
            imageAttachmentData: nil
        )
        spending.entries = [
            TransactionEntry(amountCents: -300_00, category: .needs, group: spending),
            TransactionEntry(amountCents: -700_00, category: .wants, group: spending),
            TransactionEntry(amountCents: -100_00, category: .savingsAndDebts, group: spending)
        ]

        month.transactionGroups = [salary, spending]

        #expect(month.spentAmount(in: .all) == 1100.0)
        #expect(month.incomeAmount(in: .all) == 2000.0)
        #expect(month.remainingAmount(in: .all) == 900.0)
        #expect(month.overSpending(in: .all) == false)

        #expect(month.spentAmount(in: .category(.savingsAndDebts)) == 100.0)
        #expect(month.remainingAmount(in: .category(.wants)) == -100.0)
        #expect(month.overSpending(in: .category(.wants)))
        #expect(month.overSpending(in: .category(.needs)) == false)

        let summedSpent = BudgetCategory.allCases.reduce(0.0) { $0 + month.spentAmount(in: .category($1)) }
        #expect(summedSpent == month.spentAmount(in: .all))
    }

}
