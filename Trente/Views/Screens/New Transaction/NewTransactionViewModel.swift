//
//  NewTransactionViewModel.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 14/07/2025.
//

import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class NewTransactionViewModel {
    // Transaction Data
    var request = TransactionCreationRequest()
    
    // View State
    var step: NewTransactionStep = .amountCategory
    var nextButtonDisabled: Bool = true
    var isRepartitionComplete: Bool = false
    var showErrorAlert: Bool = false

    @ObservationIgnored private let permissionService: NotificationPermissionService
    @ObservationIgnored private(set) var permissionRequest: Task<Void, Never>?

    init(permissionService: NotificationPermissionService = NotificationPermissionService()) {
        self.permissionService = permissionService
    }
    
    var filteredSteps: [NewTransactionStep] {
        var steps: [NewTransactionStep] = [.amountCategory, .title, .notesImage]
        if request.type == .income { steps.append(.repartition) }
        if request.isRecurrent { steps.append(.recurrence) }
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

    func createTransaction(for month: Month, in context: ModelContext) -> Bool {
        do {
            try TransactionService.shared.create(with: request, for: month, in: context)
        } catch {
            showErrorAlert = true
            return false
        }
        if request.isRecurrent {
            permissionRequest = Task { [permissionService] in
                _ = await permissionService.requestIfNeeded()
            }
        }
        return true
    }
}
