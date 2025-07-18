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
    // TODO: Try to factorize redundant code
    // TODO: Move the logic elsewhere in the code, maybe?
    func createTransaction(for month: Month, in context: ModelContext) throws {
        // MARK: Recurring Transaction
        if isRecurrent {
            let rule: RecurringTransactionRule = .init(
                title: title,
                frequency: recurrenceFrequency,
                startDate: recurrenceStartDate,
                endDate: recurrenceEndDate,
                repartition: repartition
            )
            context.insert(rule)
            
            // TODO: Make this function refresh instances instead of generating them
            try RecurringTransactionService.shared.refreshInstances(for: month, in: context)

            if Calendar.current.isDateInToday(recurrenceStartDate) {
                let group: TransactionGroup = .init(
                    title: title,
                    type: type,
                    month: month,
                    note: notes,
                    imageAttachmentData: imageData
                )
                context.insert(group)
                
                if type == .expense, let category = selectedCategory {
                    let entry: TransactionEntry = .init(
                        amountCents: amountCents,
                        category: category,
                        group: group
                    )
                    context.insert(entry)
                } else if type == .income {
                    for (category, amount) in repartition {
                        let entry: TransactionEntry = .init(
                            amountCents: amount,
                            category: category,
                            group: group
                        )
                        context.insert(entry)
                    }
                }
            }
        } else {
            // MARK: Non-Recurring Transaction
            let group: TransactionGroup = .init(
                title: title,
                type: type,
                month: month,
                note: notes,
                imageAttachmentData: imageData
            )
            context.insert(group)

            if type == .expense, let category = selectedCategory {
                let entry: TransactionEntry = .init(
                    amountCents: amountCents,
                    category: category,
                    group: group
                )
                context.insert(entry)
            } else if type == .income {
                for (category, amount) in repartition where amount > 0 {
                    let entry = TransactionEntry(
                        amountCents: amount,
                        category: category,
                        group: group
                    )
                    context.insert(entry)
                }
            }
        }
        
        do {
            try context.save()
            print("Transaction creation completed")
        } catch {
            print("Failed to save transaction: \(error)")
        }
    }
}
