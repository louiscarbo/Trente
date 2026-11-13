//
//  NewTransactionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/04/2025.
//

import SwiftUI
import SwiftData

struct NewTransactionView: View {
    // View Arguments
    let context: NewTransactionContext
    private var month: Month? { modelContext.model(for: context.monthID) as? Month }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Transaction Data
    @State private var viewModel = NewTransactionViewModel()
    @FocusState private var focusedField: NewTransactionField?

    var body: some View {
        NavigationStack {
            stepsView
                .keyboardDismissButton(isVisible: focusedField != nil) {
                    focusedField = nil
                }
                .safeAreaInset(edge: .bottom) {
                    navigationButtons
                }
        }
        .onAppear {
            if let month {
                viewModel.setMonth(month)
            }
        }
        .onChange(of: viewModel.step) { _, newStep in
            if newStep != .title {
                focusedField = nil
            }
        }
        .alert("An error occurred", isPresented: $viewModel.showErrorAlert) {
            Button("Retry") {
                guard let month else { return }
                _ = viewModel.createTransaction(for: month, in: modelContext)
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("We couldn't create the transaction. Please try again.")
        }
    }
    
    private var navigationButtons: some View {
        StepNavigationBar(
            showsPrevious: viewModel.showPreviousButton,
            nextTitle: viewModel.isLastStep ? "Create" : "Next",
            canAdvance: viewModel.canAdvance,
            onPrevious: {
                withAnimation(.bouncy) {
                    viewModel.previousStep()
                }
            },
            onNext: advance
        )
    }

    private func advance() {
        withAnimation {
            if viewModel.isLastStep {
                guard let month else { return }
                if viewModel.createTransaction(for: month, in: modelContext) {
                    dismiss()
                }
            } else {
                viewModel.nextStep()
            }
        }
    }
    
    private var stepsView: some View {
        Group {
            switch viewModel.step {
            case .amountCategory:
                AmountCategoryView(
                    selectedCategory: $viewModel.request.selectedCategory,
                    amountCents: $viewModel.request.amountCents,
                    transactionType: $viewModel.request.type,
                    isRecurrent: $viewModel.request.isRecurrent,
                    currency: context.currency
                )
                #if os(iOS)
                .toolbar {
                    CloseToolbarItem { dismiss() }
                }
                #endif
            case .title:
                TitleView(
                    title: $viewModel.request.title,
                    focusedField: $focusedField
                )
            case .notesImage:
                NotesImageView(
                    imageData: viewModel.request.imageData,
                    isLoadingImage: viewModel.isLoadingImage,
                    notes: $viewModel.request.notes,
                    focusedField: $focusedField,
                    imageLoadingError: $viewModel.imageLoadingError
                ) { item in
                    viewModel.loadImage { try await item.loadTransferable(type: Data.self) }
                }
            case .repartition:
                IncomeRepartitionView(
                    currency: context.currency,
                    transactionAmount: viewModel.request.amountCents,
                    repartition: $viewModel.request.repartition,
                    isRepartitionComplete: $viewModel.isRepartitionComplete,
                    prefilledMonthName: viewModel.prefilledMonthName
                )
            case .recurrence:
                RecurrenceView(
                    recurrenceFrequency: $viewModel.request.recurrenceFrequency,
                    recurrenceStartDate: $viewModel.request.recurrenceStartDate,
                    recurrenceEndDate: $viewModel.request.recurrenceEndDate
                )
            }
            
        }
        .navigationTitle("New Transaction")
        .toolbarTitleDisplayMode(.inline)
    }
}

enum NewTransactionField {
    case title
    case notes
}

enum NewTransactionStep: CaseIterable {
    case amountCategory
    case title
    case repartition
    case notesImage
    case recurrence
}

struct NewTransactionContext: Codable, Hashable {
    let currency: Currency
    let monthID: PersistentIdentifier
}

extension NewTransactionContext: Identifiable {
    var id: PersistentIdentifier { monthID }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            NewTransactionView(
                context: .init(currency: Currencies.currency(for: "EUR")!, monthID: Month.month1.persistentModelID)
            )
        }
}
