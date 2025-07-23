//
//  NewTransactionViewModel.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 14/07/2025.
//

import SwiftUI
import SwiftData

@MainActor
class NewTransactionViewModel: ObservableObject {
    // Transaction Data
    @Published var selectedCategory: BudgetCategory?
    @Published var amountCents: Int = 0
    @Published var type: TransactionType = .expense
    @Published var title: String = ""
    @Published var isRecurrent: Bool = false
    @Published var imageData: Data?
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
    
    // TODO: Make it handle the error with an error as a published property
    // TODO: Move the logic elsewhere in the code, maybe?
    func createTransaction(for month: Month, in context: ModelContext) {
        let request = TransactionCreationRequest(
            title: title,
            amountCents: amountCents,
            type: type,
            selectedCategory: selectedCategory,
            notes: notes,
            imageData: imageData,
            isRecurrent: isRecurrent,
            repartition: repartition,
            recurrenceFrequency: recurrenceFrequency,
            recurrenceStartDate: recurrenceStartDate,
            recurrenceEndDate: recurrenceEndDate
        )
        
        do {
            try TransactionService.shared.create(with: request, for: month, in: context)
        } catch {
            print("Failed to save transaction: \(error)")
            self.error = error
        }
    }
}
