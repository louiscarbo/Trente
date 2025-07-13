//
//  NewTransactionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/04/2025.
//

import SwiftUI

// TODO: adapt to macOS
// TODO: Split into different files
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
        step != .repartitionRecurrence
    }
    @State private var nextButtonDisabled: Bool = true
    
    // View State
    @State private var step: NewTransactionStep = .amountCategory
    @State private var showKeyboardDismissButton: Bool = false
    @State private var isRepartitionComplete: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                #if os(iOS)
                iOSTabView
                #else
                macOSConditionalView
                #endif
                navigationButtons
            }
        }
    }
    
    var iOSTabView: some View {
        TabView(selection: $step) {
            AmountCategoryView(
                selectedCategory: $selectedCategory,
                amountCents: $amountCents,
                transactionType: $type,
                nextButtonDisabled: $nextButtonDisabled,
                isRecurrent: $isRecurrent,
                
                currencyCode: currency.isoCode
            )
            .newTransactionPage(tag: .amountCategory)
            
            TitleView(
                title: $title,
                nextButtonDisabled: $nextButtonDisabled,
                step: $step,
                showKeyboardDismissButton: $showKeyboardDismissButton
            )
            .newTransactionPage(tag: .title)
            
            NotesImageView(
                image: $image,
                notes: $notes,
                showKeyboardDismissButton: $showKeyboardDismissButton
            )
            .newTransactionPage(tag: .notesImage)
            
            RepartitionRecurrenceView(
                currency: currency,
                transactionAmount: amountCents,
                repartition: $repartition,
                isRepartitionComplete: $isRepartitionComplete,
                showRecurrence: isRecurrent,
                showIncomeRepartition: type == .income
            )
            .newTransactionPage(tag: .repartitionRecurrence)
        }
        #if os(iOS)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        #elseif os(macOS)
        .tabViewStyle(.automatic)
        #endif
        .navigationTitle("New Transaction")
        .toolbarTitleDisplayMode(.inline)
    }
    
    private var navigationButtons: some View {
        VStack {
            HStack(spacing: 20) {
                if showPreviousButton {
                    Button("Previous") {
                        withAnimation {
                            if let previousStep = step.previous() {
                                step = previousStep
                            } else {
                                print("Already at the first step")
                            }
                        }
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
                }
                
                Button("Next") {
                    withAnimation {
                        if let nextStep = step.next(isRecurrent: isRecurrent, isIncome: type == .income) {
                            step = nextStep
                        } else {
                            print("Transaction creation completed")
                        }
                    }
                }
                .disabled(nextButtonDisabled)
                .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
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
    
    private var macOSConditionalView: some View {
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
                    
                    showKeyboardDismissButton: $showKeyboardDismissButton
                )
            case .repartitionRecurrence:
                RepartitionRecurrenceView(
                    currency: currency,
                    transactionAmount: amountCents,
                    repartition: $repartition,
                    isRepartitionComplete: $isRepartitionComplete,
                    showRecurrence: isRecurrent,
                    showIncomeRepartition: type == .income
                )
            }
        }
    }
    
    struct NewTransactionViewModifier: ViewModifier {
        let tag: NewTransactionStep
        
        func body(content: Content) -> some View {
            ZStack {
                Rectangle().fill(.clear)
                content
            }
            .tag(tag)
            .contentShape(Rectangle())
            .gesture(DragGesture())
        }
    }
}

enum NewTransactionStep {
    case amountCategory
    case title
    case notesImage
    case repartitionRecurrence
    
    func next(isRecurrent: Bool, isIncome: Bool) -> NewTransactionStep? {
        switch self {
        case .amountCategory:
            return .title
        case .title:
            return .notesImage
        case .notesImage:
            if isRecurrent || isIncome {
                return .repartitionRecurrence
            } else {
                return nil
            }
        case .repartitionRecurrence:
            return nil
        }
    }
    
    func previous() -> NewTransactionStep? {
        switch self {
        case .amountCategory:
            return nil
        case .title:
            return .amountCategory
        case .notesImage:
            return .title
        case .repartitionRecurrence:
            return .notesImage
        }
    }
}

extension View {
    func newTransactionPage(tag: NewTransactionStep) -> some View {
        modifier(NewTransactionView.NewTransactionViewModifier(tag: tag))
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            NewTransactionView(
                currency: Currencies.currency(for: "EUR")!
            )
        }
}
