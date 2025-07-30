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
    @Bindable private var viewModel: NewTransactionViewModel = .init()
    
    var body: some View {
        NavigationStack {
            stepsView
                .safeAreaInset(edge: .bottom) {
                    navigationButtons
                }
        }
        .alert("An error occurred", isPresented: $viewModel.showErrorAlert) {
            Button("Retry") {
                guard let month else { return }
                viewModel.createTransaction(for: month, in: modelContext)
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("We couldn't create the transaction. Please try again.")
        }
    }
    
    private var navigationButtons: some View {
        VStack {
            HStack(spacing: 20) {
                if viewModel.showPreviousButton {
                    Button("Previous") {
                        withAnimation(.bouncy) {
                            viewModel.previousStep()
                        }
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
                }
                
                if let currentIndex = viewModel.filteredSteps.firstIndex(of: viewModel.step) {
                    let isLastStep = currentIndex == viewModel.filteredSteps.count - 1
                    
                    Button(isLastStep ? "Create" : "Next") {
                        withAnimation {
                            if isLastStep {
                                guard let month else { return }
                                viewModel.createTransaction(for: month, in: modelContext)
                                dismiss()
                            } else {
                                viewModel.nextStep()
                            }
                        }
                    }
                    .disabled(viewModel.nextButtonDisabled)
                    .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
                }
            }
            
            #if os(iOS)
            // TODO: Make the showKeyboardDismissButton more robust
            if viewModel.showKeyboardDismissButton {
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    viewModel.showKeyboardDismissButton = false
                } label: {
                    Label("Done", systemImage: "keyboard.chevron.compact.down")
                }
                .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
            }
            #endif
        }
        .padding()
        .background {
            UnevenRoundedRectangle(
                cornerRadii:
                    RectangleCornerRadii(topLeading: 26, bottomLeading: 0, bottomTrailing: 0, topTrailing: 26)
            )
            .fill(.regularMaterial)
            .stroke(.secondary.opacity(0.4), lineWidth: 3)
            .ignoresSafeArea()
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
                    
                    nextButtonDisabled: $viewModel.nextButtonDisabled,
                    currencyCode: context.currency.isoCode
                )
            case .title:
                TitleView(
                    title: $viewModel.request.title,
                    
                    nextButtonDisabled: $viewModel.nextButtonDisabled,
                    step: $viewModel.step,
                    showKeyboardDismissButton: $viewModel.showKeyboardDismissButton
                )
            case .notesImage:
                NotesImageView(
                    imageData: $viewModel.request.imageData,
                    notes: $viewModel.request.notes,
                    
                    nextButtonDisabled: $viewModel.nextButtonDisabled,
                    showKeyboardDismissButton: $viewModel.showKeyboardDismissButton
                )
            case .repartition:
                IncomeRepartitionView(
                    currency: context.currency,
                    transactionAmount: viewModel.request.amountCents,
                    repartition: $viewModel.request.repartition,
                    
                    nextButtonDisabled: $viewModel.nextButtonDisabled
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

enum NewTransactionStep: CaseIterable {
    case amountCategory
    case title
    case notesImage
    case repartition
    case recurrence
}

struct NewTransactionContext: Codable, Hashable {
    let currency: Currency
    let monthID: PersistentIdentifier
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            NewTransactionView(
                context: .init(currency: Currencies.currency(for: "EUR")!, monthID: Month.month1.persistentModelID)
            )
        }
}
