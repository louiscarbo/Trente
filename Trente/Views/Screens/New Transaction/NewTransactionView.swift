//
//  NewTransactionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/04/2025.
//

import SwiftUI

struct NewTransactionView: View {
    // View Arguments
    let context: NewTransactionContext
    private var month: Month? { modelContext.model(for: context.monthID) as? Month }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Transaction Data
    @StateObject private var viewModel: NewTransactionViewModel = .init()
    
    var body: some View {
        NavigationStack {
            stepsView
                .safeAreaInset(edge: .bottom) {
                    navigationButtons
                }
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
                                do {
                                    // TODO: Find a better way of handling the case where month is nil
                                    guard let month else { return }
                                    try viewModel.createTransaction(for: month, in: modelContext)
                                    dismiss()
                                } catch {
                                    print("OOPS!! An error occured: \(error)")
                                }
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
                    selectedCategory: $viewModel.selectedCategory,
                    amountCents: $viewModel.amountCents,
                    transactionType: $viewModel.type,
                    isRecurrent: $viewModel.isRecurrent,
                    
                    nextButtonDisabled: $viewModel.nextButtonDisabled,
                    currencyCode: context.currency.isoCode
                )
            case .title:
                TitleView(
                    title: $viewModel.title,
                    
                    nextButtonDisabled: $viewModel.nextButtonDisabled,
                    step: $viewModel.step,
                    showKeyboardDismissButton: $viewModel.showKeyboardDismissButton
                )
            case .notesImage:
                NotesImageView(
                    imageData: $viewModel.imageData,
                    notes: $viewModel.notes,
                    
                    nextButtonDisabled: $viewModel.nextButtonDisabled,
                    showKeyboardDismissButton: $viewModel.showKeyboardDismissButton
                )
            case .repartition:
                IncomeRepartitionView(
                    currency: context.currency,
                    transactionAmount: viewModel.amountCents,
                    repartition: $viewModel.repartition,
                    
                    nextButtonDisabled: $viewModel.nextButtonDisabled
                )
            case .recurrence:
                RecurrenceView(
                    recurrenceFrequency: $viewModel.recurrenceFrequency,
                    recurrenceStartDate: $viewModel.recurrenceStartDate,
                    recurrenceEndDate: $viewModel.recurrenceEndDate
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

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            NewTransactionView(
                context: .init(currency: Currencies.currency(for: "EUR")!, monthID: Month.month1.persistentModelID)
            )
        }
}
