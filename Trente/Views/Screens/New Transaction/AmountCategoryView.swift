//
//  AmountCategoryView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI

struct AmountCategoryView: View {
    // Transaction Data
    @Binding var selectedCategory: BudgetCategory?
    @Binding var amountCents: Int
    @Binding var transactionType: TransactionType
    
    // View State
    @Binding var nextButtonDisabled: Bool
    @Binding var isRecurrent: Bool
    var currencyCode: String
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
                #if os(iOS)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(.system(size: 80, weight: .bold))
                .multilineTextAlignment(.center)
                #endif
            }
            
            Spacer()
            
            Toggle(isOn: $isRecurrent) {
                Text("Recurring transaction")
                    .font(.headline)
            }
            .toggleStyle(TrenteToggleStyle())
        }
        .padding([.horizontal, .bottom])
        .onChange(of: amountText) { oldValue, newValue in
            processAmountTextChange(newValue: newValue, oldValue: oldValue)
            updateNextButtonState()
        }
        .onChange(of: transactionType) { _, newValue in
            applySign()
            updateNextButtonState()
            if newValue == .income {
                selectedCategory = nil
            }
        }
        .onChange(of: selectedCategory) {
            updateNextButtonState()
        }
        .onAppear {
            updateNextButtonState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                amountFieldIsFocused = true
            }
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
            nextButtonDisabled = amountCents == 0
        } else {
            nextButtonDisabled = amountCents == 0 || selectedCategory == nil
        }
    }
}
