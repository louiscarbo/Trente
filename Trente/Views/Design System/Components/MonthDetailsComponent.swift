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
                                isRepartitionComplete: $isRepartitionComplete
                            )
                            .id(month.idealBudgetCents)
                        }
                    }
                }
                .groupBoxStyle(TrenteGroupBoxStyle())
                .animation(.bouncy, value: month.idealBudgetCents > 0)
            }
            .padding()
        }
        #if os(iOS)
        .safeAreaInset(edge: .bottom) {
            if isAmountFocused {
                VStack {
                    Button {
                        isAmountFocused = false
                    } label: {
                        Label("Done", systemImage: "keyboard.chevron.compact.down")
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
                }
                .padding()
                .background {
                    UnevenRoundedRectangle(
                        cornerRadii:
                            RectangleCornerRadii(topLeading: 26, bottomLeading: 0, bottomTrailing: 0, topTrailing: 26)
                    )
                    .offset(y: 1.5)
                    .fill(.regularMaterial)
                    .stroke(.secondary.opacity(0.4), lineWidth: 3)
                    .ignoresSafeArea()
                }
            }
        }
        #endif
    }

    private var startDatePicker: some View {
        DatePicker("Start Date", selection: $month.startDate, displayedComponents: .date)
            .datePickerStyle(.compact)
    }
    
    private var currencyPicker: some View {
        LabeledPicker(
            title: "Currency",
            selection: $month.currency,
            options: Currencies.availableCurrencies.sorted(by: { $0.localizedName < $1.localizedName })
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
            .navigationTitle(MonthFormatting.name(from: draft.startDate))
    }
}
