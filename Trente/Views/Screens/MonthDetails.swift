//
//  MonthDetails.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 31/07/2025.
//

import SwiftUI

struct MonthDetails: View {
    @Binding var month: Month
        
    @FocusState private var isAmountFocused: Bool
        
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .medium) {
                    GroupBox(label: Label("Month Details", systemImage: "calendar")) {
                        VStack(spacing: .medium) {
                            startDatePicker
                            currencyPicker
                        }
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
                    
                    GroupBox(label: Label("Ideal Budget", systemImage: month.currency.sfSymbolGaugeName)) {
                        VStack(spacing: .medium) {
                            CurrencyTextField(
                                amountCents: $month.idealBudgetCents,
                                currency: month.currency
                            )
                            .focused($isAmountFocused)
                            .font(.title)
                            .bold()
                            .multilineTextAlignment(.center)
                            .onChange(of: month.idealBudgetCents) { oldValue, newValue in
                                if newValue < oldValue {
                                    resetRepartition()
                                }
                            }
                            
                            if month.idealBudgetCents > 0 {
                                IncomeRepartitionComponent(
                                    repartition: $month.idealRepartition,
                                    amountToSplit: month.idealBudgetCents,
                                    formatter: month.currency.roundFormatter,
                                    isRepartitionComplete: .constant(false)
                                )
                                .id(UUID())
                            }
                        }
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
                    .animation(.bouncy, value: month.idealBudgetCents > 0)
                }
                .padding()
            }
            .navigationTitle("January 2025")
        }
    }

    private var startDatePicker: some View {
        DatePicker("Start Date", selection: $month.startDate, displayedComponents: .date)
            .datePickerStyle(.compact)
    }
    
    private var currencyPicker: some View {
        LabeledPicker(
            title: "Currency",
            selection: $month.currency,
            options: Currencies.availableCurrencies
        ) { currency in
            Label(currency.localizedName, systemImage: currency.sfSymbolName ?? "xmark")
        }
    }
    
    private func resetRepartition() {
        month.idealRepartition = Dictionary(
            uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) })
    }
}

#Preview {
    @Previewable @State var month: Month = .init(
        startDate: .now,
        currency: Currencies.currency(for: "EUR")!,
        idealBudgetCents: 100000, // 1000 EUR
        idealRepartition: Dictionary(
            uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) }
        )
    )
    
    return MonthDetails(month: $month)
}
