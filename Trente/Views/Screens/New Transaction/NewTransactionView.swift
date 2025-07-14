//
//  NewTransactionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/04/2025.
//

import SwiftUI

// TODO: adapt to macOS
struct NewTransactionView: View {
    // View Arguments
    var currency: Currency
    
    // Transaction Data
    @State private var selectedCategory: BudgetCategory?
    @State private var amountCents: Int = 0
    @State private var type: TransactionType = .expense
    @State private var title: String = ""
    @State private var isRecurrent: Bool = false
    @State private var image: Image?
    @State private var notes: String = ""
    @State private var recurrenceFrequency: RecurrenceFrequency = .monthly
    @State private var recurrenceStartDate: Date = Date()
    @State private var recurrenceEndDate: Date?
    @State private var repartition: [BudgetCategory: Int] = .init(
            uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) }
        )
    
    // Buttons Logic
    private var showPreviousButton: Bool {
        step != .amountCategory
    }
    private var showNextButton: Bool {
        step != .recurrence
    }
    @State private var nextButtonDisabled: Bool = true
    
    // View State
    @State private var step: NewTransactionStep = .amountCategory
    @State private var showKeyboardDismissButton: Bool = false
    @State private var isRepartitionComplete: Bool = false
    
    private var filteredSteps: [NewTransactionStep] {
        var steps: [NewTransactionStep] = [.amountCategory, .title, .notesImage]
        if type == .income { steps.append(.repartition) }
        if isRecurrent { steps.append(.recurrence) }
        return steps
    }
    
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
                if let currentIndex = filteredSteps.firstIndex(of: step), currentIndex > 0 {
                    Button("Previous") {
                        withAnimation {
                            step = filteredSteps[currentIndex - 1]
                        }
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
                }
                
                if let currentIndex = filteredSteps.firstIndex(of: step) {
                    let isLastStep = currentIndex == filteredSteps.count - 1
                    
                    Button(isLastStep ? "Create" : "Next") {
                        withAnimation {
                            if isLastStep {
                                // Handle final transaction creation
                                print("Transaction creation completed")
                            } else {
                                step = filteredSteps[currentIndex + 1]
                            }
                        }
                    }
                    .disabled(nextButtonDisabled)
                    .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
                }
            }
            
            #if os(iOS)
            if showKeyboardDismissButton {
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    showKeyboardDismissButton = false
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
            switch step {
            case .amountCategory:
                AmountCategoryView(
                    selectedCategory: $selectedCategory,
                    amountCents: $amountCents,
                    transactionType: $type,
                    nextButtonDisabled: $nextButtonDisabled,
                    isRecurrent: $isRecurrent,
                    
                    currencyCode: currency.isoCode
                )
            case .title:
                TitleView(
                    title: $title,
                    
                    nextButtonDisabled: $nextButtonDisabled,
                    step: $step,
                    showKeyboardDismissButton: $showKeyboardDismissButton
                )
            case .notesImage:
                NotesImageView(
                    image: $image,
                    notes: $notes,
                    
                    nextButtonDisabled: $nextButtonDisabled,
                    showKeyboardDismissButton: $showKeyboardDismissButton
                )
            case .repartition:
                IncomeRepartitionView(
                    currency: currency,
                    transactionAmount: amountCents,
                    repartition: $repartition,
                    isRepartitionComplete: $isRepartitionComplete
                )
            case .recurrence:
                EmptyView()
//                RecurrenceView()
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
                currency: Currencies.currency(for: "EUR")!
            )
        }
}
