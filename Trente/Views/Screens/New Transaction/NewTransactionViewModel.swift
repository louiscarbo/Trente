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
    private(set) var isLoadingImage: Bool = false
    var imageLoadingError: String?

    @ObservationIgnored private let permissionService: NotificationPermissionService
    @ObservationIgnored private(set) var permissionRequest: Task<Void, Never>?
    @ObservationIgnored private(set) var imageLoad: Task<Void, Never>?

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
    
    func loadImage(_ loadData: @escaping @Sendable () async throws -> Data?) {
        imageLoad?.cancel()
        isLoadingImage = true
        imageLoad = Task {
            var preparedData: Data?
            if let loadedData = try? await loadData() {
                preparedData = await ImageAttachment.prepared(loadedData)
            }
            guard !Task.isCancelled else { return }
            if let preparedData {
                request.imageData = preparedData
            } else {
                imageLoadingError = String(localized: "The image could not be loaded. Please try again.")
            }
            isLoadingImage = false
        }
    }

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
