//
//  MonthDetailsComponent.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 31/07/2025.
//

import SwiftUI

struct MonthDetailsComponent: View {
    @Binding var month: MonthDraft
    @Binding var isRepartitionComplete: Bool

    @FocusState private var isAmountFocused: Bool
        
    var body: some View {
        VStack(spacing: .medium) {
            GroupBox(label: Label("Month Details", systemImage: "calendar")) {
                VStack(spacing: .medium) {
                    MonthStartDatePicker(startDate: $month.startDate)
                    MonthCurrencyPicker(currency: $month.currency)
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
            
            GroupBox(label: Label("Ideal Budget", systemImage: month.currency.sfSymbolGaugeName)) {
                VStack(spacing: .medium) {
                    IdealBudgetField(
                        amountCents: $month.idealBudgetCents,
                        currency: month.currency,
                        isFocused: $isAmountFocused
                    )
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
                            isRepartitionComplete: $isRepartitionComplete
                        )
                        .id(month.idealBudgetCents)
                    }
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
            .animation(.bouncy, value: month.idealBudgetCents > 0)
        }
        .keyboardDismissButton(isVisible: isAmountFocused) { isAmountFocused = false }
    }

    private func resetRepartition() {
        month.idealRepartition = Dictionary(
            uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) })
    }
}

#Preview {
    @Previewable @State var draft: MonthDraft = .init(
        startDate: .now,
        currency: Currencies.currency(for: "EUR")!,
        idealBudgetCents: 100000,
        idealRepartition: Dictionary(
            uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) }
        )
    )
    @Previewable @State var isRepartitionComplete: Bool = false
    
    NavigationStack {
        MonthDetailsComponent(month: $draft, isRepartitionComplete: $isRepartitionComplete)
            .navigationTitle(Month.name(startingOn: draft.startDate))
    }
}
