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
    var isRepartitionComplete: Bool = false
    var showErrorAlert: Bool = false
    let imageLoader = ImageAttachmentLoader()

    @ObservationIgnored private let permissionService: NotificationPermissionService
    @ObservationIgnored private(set) var permissionRequest: Task<Void, Never>?
    @ObservationIgnored private var repartitionAmountCents: Int?

    init(permissionService: NotificationPermissionService = NotificationPermissionService()) {
        self.permissionService = permissionService
    }
    
    var filteredSteps: [NewTransactionStep] {
        var steps: [NewTransactionStep] = [.amountCategory, .title]
        if request.type == .income { steps.append(.repartition) }
        steps.append(.notesImage)
        if request.isRecurrent { steps.append(.recurrence) }
        return steps
    }
    
    var showPreviousButton: Bool { step != .amountCategory }

    var isLastStep: Bool { step == filteredSteps.last }

    var canAdvance: Bool {
        guard !(isLastStep && isLoadingImage) else { return false }
        return switch step {
        case .amountCategory:
            request.amountCents != 0 && (request.type == .income || request.selectedCategory != nil)
        case .title:
            !request.title.isEmpty
        case .repartition:
            isRepartitionComplete
        case .notesImage, .recurrence:
            true
        }
    }
    
    var isLoadingImage: Bool { imageLoader.isLoading }

    var imageLoadingError: String? {
        get { imageLoader.error }
        set { imageLoader.error = newValue }
    }

    func loadImage(_ loadData: @escaping @Sendable () async throws -> Data?) {
        imageLoader.load(loadData) { [request] preparedData in
            request.imageData = preparedData
        }
    }

    func nextStep() {
        if let currentIndex = filteredSteps.firstIndex(of: step) {
            let isLastStep = currentIndex == filteredSteps.count - 1
            if !isLastStep {
                step = filteredSteps[currentIndex + 1]
            }
        }
        if step == .repartition {
            prepareRepartition()
        }
    }

    private func prepareRepartition() {
        guard repartitionAmountCents != request.amountCents else { return }
        request.repartition = Dictionary(uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) })
        repartitionAmountCents = request.amountCents
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
