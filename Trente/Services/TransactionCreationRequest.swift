//
//  TransactionCreationRequest.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/07/2025.
//

import Foundation

@MainActor
@Observable
final class TransactionCreationRequest {
    var title: String = ""
    var amountCents: Int = 0 {
        didSet {
            let signedAmount = signed(amountCents)
            if amountCents != signedAmount {
                amountCents = signedAmount
            }
        }
    }
    var type: TransactionType = .expense {
        didSet {
            amountCents = signed(amountCents)
            if type == .income {
                selectedCategory = nil
            }
        }
    }
    var selectedCategory: BudgetCategory? = nil
    var notes: String = ""
    var imageData: Data? = nil
    var isRecurrent: Bool = false
    var date: Date = .now

    var repartition: [BudgetCategory: Int] = [:]

    var recurrenceFrequency: RecurrenceFrequency = .monthly
    var recurrenceStartDate: Date = .now
    var recurrenceEndDate: Date? = nil

    private func signed(_ cents: Int) -> Int {
        type == .income ? abs(cents) : -abs(cents)
    }
}
