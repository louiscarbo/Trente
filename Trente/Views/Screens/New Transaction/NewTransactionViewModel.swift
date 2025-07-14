//
//  NewTransactionViewModel.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 14/07/2025.
//

import SwiftUI

class NewTransactionViewModel: ObservableObject {
    // Transaction Data
    @Published var selectedCategory: BudgetCategory?
    @Published var amountCents: Int = 0
    @Published var type: TransactionType = .expense
    @Published var title: String = ""
    @Published var isRecurrent: Bool = false
    @Published var image: Image?
    @Published var notes: String = ""
    @Published var recurrenceFrequency: RecurrenceFrequency = .monthly
    @Published var recurrenceStartDate: Date = Date()
    @Published var recurrenceEndDate: Date?
    @Published var repartition: [BudgetCategory: Int] = [:]
    
    // View State
    @Published var step: NewTransactionStep = .amountCategory
    @Published var nextButtonDisabled: Bool = true
    @Published var showKeyboardDismissButton: Bool = false
    @Published var isRepartitionComplete: Bool = false
    
    var filteredSteps: [NewTransactionStep] {
        var steps: [NewTransactionStep] = [.amountCategory, .title, .notesImage]
        if type == .income { steps.append(.repartition) }
        if isRecurrent { steps.append(.recurrence) }
        return steps
    }
    
    var showPreviousButton: Bool { step != .amountCategory }
    
    var showNextButton: Bool { step != .recurrence }
    
    func nextStep() {
        if let currentIndex = filteredSteps.firstIndex(of: step) {
            let isLastStep = currentIndex == filteredSteps.count - 1
            if !isLastStep {
                step = filteredSteps[currentIndex + 1]
            }
        }
    }
    
    func previousStep() {
        if let currentIndex = filteredSteps.firstIndex(of: step), currentIndex > 0 {
            step = filteredSteps[currentIndex - 1]
        }
    }
    
    func createTransaction() {
        // TODO: Implement transaction creation
        print("Transaction creation completed")
    }
}
