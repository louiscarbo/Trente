//
//  TransactionCreationRequestTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Testing
@testable import Trente

@MainActor
struct TransactionCreationRequestTests {
    @Test("Switching an expense to an income makes the amount positive and clears the category")
    func switchingToIncome() {
        let request = TransactionCreationRequest()
        request.amountCents = -25_00
        request.selectedCategory = .wants

        request.type = .income

        #expect(request.amountCents == 25_00)
        #expect(request.selectedCategory == nil)
    }

    @Test("Switching back to an expense makes the amount negative")
    func switchingBackToExpense() {
        let request = TransactionCreationRequest()
        request.type = .income
        request.amountCents = 25_00

        request.type = .expense

        #expect(request.amountCents == -25_00)
    }

    @Test("Amounts typed take the sign of the transaction type", arguments: [TransactionType.expense, .income])
    func typedAmountTakesTheSign(type: TransactionType) {
        let request = TransactionCreationRequest()
        request.type = type

        request.amountCents = 12_00

        #expect(request.amountCents == (type == .income ? 12_00 : -12_00))
    }
}
