//
//  NewTransactionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/04/2025.
//

import SwiftUI

struct NewTransactionView: View {
    // View Arguments
    var currency: Currency
    
    // Transaction Data
    @State private var selectedCategory: BudgetCategory? = nil
    @State private var amountCents: Int = 0
    @State private var type: TransactionType = .expense
    @State private var title: String = ""
    @State private var isRecurrent: Bool = false
    
    // Buttons Logic
    var showPreviousButton: Bool {
        step != .amountCategory
    }
    var showNextButton: Bool {
        step != .recurrence
    }
    
    // View State
    @State private var step: NewTransactionStep = .amountCategory
    @State var nextButtonDisabled: Bool = true
        
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $step) {
                    AmountCategorySelectionView(
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
                        nextButtonDisabled: $nextButtonDisabled
                    )
                    .newTransactionPage(tag: .title)
                    
                    RecurrenceView()
                        .newTransactionPage(tag: .recurrence)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .navigationTitle("New Transaction")
                .toolbarTitleDisplayMode(.inline)
                
                navigationButtons
            }
        }
    }
    
    var navigationButtons: some View {
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
                .frame(height: 20)
                .buttonStyle(TrenteButtonStyle(narrow: true))
            }
            
            Button("Next") {
                withAnimation {
                    if let nextStep = step.next() {
                        step = nextStep
                    } else {
                        print("Transaction creation completed")
                    }
                }
            }
            .disabled(nextButtonDisabled)
            .frame(height: 20)
            .buttonStyle(TrenteButtonStyle(narrow: true))
        }
        .padding(30)
    }
    
    enum NewTransactionStep {
        case amountCategory
        case title
        case recurrence
        
        func next() -> NewTransactionStep? {
            switch self {
            case .amountCategory:
                return .title
            case .title:
                return .recurrence
            case .recurrence:
                return nil
            }
        }
        
        func previous() -> NewTransactionStep? {
            switch self {
            case .amountCategory:
                return nil
            case .title:
                return .amountCategory
            case .recurrence:
                return .title
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

extension View {
    func newTransactionPage(tag: NewTransactionView.NewTransactionStep) -> some View {
        modifier(NewTransactionView.NewTransactionViewModifier(tag: tag))
    }
}

// MARK: AmountCategorySelectionView
private struct AmountCategorySelectionView: View {
    // Bindings
    @Binding var selectedCategory: BudgetCategory?
    @Binding var amountCents: Int
    @Binding var transactionType: TransactionType
    @Binding var nextButtonDisabled: Bool
    @Binding var isRecurrent: Bool
    
    // View arguments
    var currencyCode: String
    
    // View State
    @State private var amountText = ""
    @FocusState private var amountFieldIsFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            if transactionType == .expense {
                Picker("Select Category", selection: $selectedCategory) {
                    ForEach(BudgetCategory.allCases, id: \.self) { category in
                        Text(category.shortName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                Spacer()
                    .frame(height: 25)
            }
            
            Label(transactionType == .income
                  ? "You will select categories for this income in the next steps."
                  : selectedCategory?.shortExamples ?? "Select a category for this transaction.", systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 0) {
                Picker("Income/Expense", selection: $transactionType) {
                    Image(systemName: "minus").tag(TransactionType.expense)
                    Image(systemName: "plus").tag(TransactionType.income)
                }
                .pickerStyle(.inline)
                .frame(width: 60)
                
                TextField(
                    "",
                    text: $amountText,
                    prompt: Text("\(0.formatted(.currency(code: currencyCode)))")
                )
                .focused($amountFieldIsFocused)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(.system(size: 80, weight: .bold))
                .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Toggle(isOn: $isRecurrent) {
                Text("Recurring transaction")
                    .font(.headline)
            }
            .toggleStyle(TrenteToggleStyle())
        }
        .padding(.horizontal)
        .onChange(of: amountText) { oldValue, newValue in
            processAmountTextChange(newValue: newValue, oldValue: oldValue)
            updateNextButtonState()
            print("AmountCents: \(amountCents), transactionType: \(transactionType)")
        }
        .onChange(of: transactionType) { oldValue, newValue in
            applySign()
            updateNextButtonState()
            
            if newValue == .income {
                selectedCategory = nil
            }
        }
        .onChange(of: selectedCategory) {
            updateNextButtonState()
        }
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                amountFieldIsFocused = true
            }
            updateNextButtonState()
        }
    }
    
    // Text validation and amount in cents calculation
    private func processAmountTextChange(newValue: String, oldValue: String) {
        let decimalSep = Locale.current.decimalSeparator ?? "."

        // 1) Strip any leading sign for validation
        let unsigned = newValue.trimmingCharacters(in: CharacterSet(charactersIn: "+-"))

        // 1a) Prevent more than one decimal separator
        let sepChar = Character(decimalSep)
        let sepCount = unsigned.filter { $0 == sepChar }.count
        if sepCount > 1 {
            amountText = oldValue
            return
        }

        // 1b) Enforce max two decimal places
        if let idx = unsigned.firstIndex(of: sepChar) {
            let frac = unsigned[unsigned.index(after: idx)...]
            if frac.count > 2 {
                amountText = oldValue
                return
            }
        }

        // 1c) If now empty, clear everything
        guard !unsigned.isEmpty else {
            amountText = ""
            amountCents = 0
            return
        }

        // 1d) Parse number respecting locale
        let fmt = NumberFormatter()
        fmt.locale = Locale.current
        fmt.numberStyle = .decimal
        let dbl = fmt.number(from: unsigned)?.doubleValue ?? 0

        // 1e) Compute absolute cents
        let absCents = Int((dbl * 100).rounded())

        // 1f) Update the text to the unsigned digits
        amountText = unsigned

        // 1g) Store signed cents & re-attach sign
        amountCents = transactionType == .income ? absCents : -absCents
        applySign()
    }

    private func applySign() {
        // 2a) Normalize amountCents to match isIncome
        if transactionType == .income {
            amountCents = abs(amountCents)
        } else {
            amountCents = -abs(amountCents)
        }

        // 2b) Rebuild amountText with proper prefix
        let unsigned = amountText.trimmingCharacters(in: CharacterSet(charactersIn: "+-"))
        let prefix = transactionType == .income ? "" : "-"
        amountText = prefix + unsigned
    }
    
    private func updateNextButtonState() {
        if transactionType == .income {
            if amountCents != 0 {
                nextButtonDisabled = false
            } else {
                nextButtonDisabled = true
            }
        } else {
            if amountCents != 0 && selectedCategory != nil {
                nextButtonDisabled = false
            } else {
                nextButtonDisabled = true
            }
        }
    }
}

// MARK: TitleView
private struct TitleView: View {
    @Binding var title: String
    @Binding var nextButtonDisabled: Bool
    
    @FocusState private var titleFieldIsFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                Label("Give a title to your transaction", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                TextField(
                    "",
                    text: $title,
                    prompt: Text("Title"),
                    axis: .vertical
                )
                .lineLimit(3)
                .focused($titleFieldIsFocused)
                .textFieldStyle(.plain)
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: title) {
            updateNextButtonState()
        }
        .onAppear {
            updateNextButtonState()
            titleFieldIsFocused = true
        }
        .onDisappear {
            titleFieldIsFocused = false
        }
    }
    
    private func updateNextButtonState() {
        if title.isEmpty {
            nextButtonDisabled = true
        } else {
            nextButtonDisabled = false
        }
    }
}

private struct RecurrenceView: View {
    var body: some View {
        VStack {
            Text("Select Recurrence")
                .font(.headline)
            // Add your UI elements here
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            NewTransactionView(currency: Currency(isoCode: "EUR", symbol: "eurosign", localizedName: "Euro"))
        }
}
