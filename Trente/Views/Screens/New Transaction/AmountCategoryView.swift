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
    @FocusState private var currencyTextFieldFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var amountFontSize = 80
    let currency: Currency
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(transactionType == .income
                  ? String(localized: "You will select categories for this income in the next steps.")
                  : selectedCategory?.shortExamples ?? String(localized: "Select a category for this transaction."), systemImage: "info.circle")
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
            if newValue == .income {
                selectedCategory = nil
            }
        }
        .onChange(of: amountCents) {
            amountCents = (transactionType == .income) ? abs(amountCents) : -abs(amountCents)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            currencyTextFieldFocused = true
        }
    }
    
    @ViewBuilder
    private var stackContent: some View {
        #if os(iOS)
        Picker("Income/Expense", selection: $transactionType) {
            Label("Expense", systemImage: "minus").tag(TransactionType.expense)
            Label("Income", systemImage: "plus").tag(TransactionType.income)
        }
        .labelStyle(.iconOnly)
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
            .font(.system(size: amountFontSize, weight: .bold))
            .multilineTextAlignment(.center)
            #endif
    }
}

#Preview {
    @Previewable @State var category: BudgetCategory? = .needs
    @Previewable @State var amount: Int = -2550
    @Previewable @State var type: TransactionType = .expense
    @Previewable @State var recurrent: Bool = false
    let euro = Currencies.availableCurrencies.first { $0.isoCode == "EUR" }!
    
    AmountCategoryView(
        selectedCategory: $category,
        amountCents: $amount,
        transactionType: $type,
        isRecurrent: $recurrent,
        currency: euro
    )
    .padding()
}
