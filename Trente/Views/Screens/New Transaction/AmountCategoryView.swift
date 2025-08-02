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
    @Binding var isRecurrent: Bool
    
    // View State
    @Binding var nextButtonDisabled: Bool
    @FocusState private var currencyTextFieldFocused: Bool
    let currency: Currency
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(transactionType == .income
                  ? "You will select categories for this income in the next steps."
                  : selectedCategory?.shortExamples ?? "Select a category for this transaction.", systemImage: "info.circle")
            .font(.headline)
            .foregroundStyle(.secondary)

            if transactionType == .expense {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(BudgetCategory.allCases) { category in
                        Text(category.shortName).tag(category as BudgetCategory?)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Spacer()
            
            #if os(iOS)
            HStack(spacing: 0) {
                stackContent
            }
            #elseif os(macOS)
            stackContent
            #endif
            
            Spacer()
            
            Toggle(isOn: $isRecurrent) {
                Text("Recurring transaction")
                    .font(.headline)
            }
            .toggleStyle(TrenteToggleStyle())
        }
        .padding([.horizontal, .bottom])
        #if os(macOS)
        .padding(.top)
        #endif
        .onChange(of: transactionType) { _, newValue in
            amountCents = (newValue == .income) ? abs(amountCents) : -abs(amountCents)
            updateNextButtonState()
            if newValue == .income {
                selectedCategory = nil
            }
        }
        .onChange(of: selectedCategory) {
            updateNextButtonState()
        }
        .onChange(of: amountCents) {
            amountCents = (transactionType == .income) ? abs(amountCents) : -abs(amountCents)
            updateNextButtonState()
        }
        .onAppear {
            updateNextButtonState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                currencyTextFieldFocused = true
            }
        }
    }
    
    @ViewBuilder
    private var stackContent: some View {
        #if os(iOS)
        Picker("Income/Expense", selection: $transactionType) {
            Image(systemName: "minus").tag(TransactionType.expense)
            Image(systemName: "plus").tag(TransactionType.income)
        }
        .pickerStyle(.inline)
        .frame(width: 60)
        #elseif os(macOS)
        Picker("Type", selection: $transactionType) {
            Label("Expense", systemImage: "minus").tag(TransactionType.expense)
            Label("Income", systemImage: "plus").tag(TransactionType.income)
        }
        .pickerStyle(.segmented)
        #endif
        
        CurrencyTextField(amountCents: $amountCents, currency: currency)
            .focused($currencyTextFieldFocused)
            #if os(iOS)
            .textFieldStyle(.plain)
            .font(.system(size: 80, weight: .bold))
            .multilineTextAlignment(.center)
            #endif
    }
    
    private func updateNextButtonState() {
        if transactionType == .income {
            nextButtonDisabled = amountCents == 0
        } else {
            nextButtonDisabled = amountCents == 0 || selectedCategory == nil
        }
    }
}

#Preview {
    @Previewable @State var category: BudgetCategory? = .needs
    @Previewable @State var amount: Int = -2550
    @Previewable @State var type: TransactionType = .expense
    @Previewable @State var recurrent: Bool = false
    @Previewable @State var disabled: Bool = false
    let euro = Currencies.availableCurrencies.first { $0.isoCode == "EUR" }!
    
    AmountCategoryView(
        selectedCategory: $category,
        amountCents: $amount,
        transactionType: $type,
        isRecurrent: $recurrent,
        nextButtonDisabled: $disabled,
        currency: euro
    )
    .padding()
    
    Button("NEXT") { }
        .buttonStyle(TrentePrimaryButtonStyle())
        .disabled(disabled)
        .padding()
}
