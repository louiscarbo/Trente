//
//  TransactionCreationRequest.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/07/2025.
//

import Foundation

struct TransactionCreationRequest {
    let title: String
    let amountCents: Int
    let type: TransactionType
    let selectedCategory: BudgetCategory?
    let notes: String
    let imageData: Data?
    let isRecurrent: Bool
    
    let repartition: [BudgetCategory: Int]
    
    let recurrenceFrequency: RecurrenceFrequency
    let recurrenceStartDate: Date
    let recurrenceEndDate: Date?
}
