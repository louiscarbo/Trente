//
//  TransactionCreationRequest.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/07/2025.
//

import Foundation

@Observable
class TransactionCreationRequest {
    var title: String = ""
    var amountCents: Int = 0
    var type: TransactionType = .expense
    var selectedCategory: BudgetCategory? = nil
    var notes: String = ""
    var imageData: Data? = nil
    var isRecurrent: Bool = false
    
    var repartition: [BudgetCategory: Int] = [:]
    
    var recurrenceFrequency: RecurrenceFrequency = .monthly
    var recurrenceStartDate: Date = .now
    var recurrenceEndDate: Date? = nil
}
