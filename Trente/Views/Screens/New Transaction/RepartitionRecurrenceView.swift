//
//  RepartitionRecurrenceView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI

struct RepartitionRecurrenceView: View {
    // Transaction Data
    let currency: Currency
    var transactionAmount: Int
    @Binding var repartition: [BudgetCategory: Int]
    @Binding var isRepartitionComplete: Bool
    
    // View State
    var showRecurrence: Bool
    var showIncomeRepartition: Bool
        
    var body: some View {
        ScrollView {
            VStack(spacing: .large) {
                if showIncomeRepartition {
                    IncomeRepartitionView(
                        currency: currency,
                        transactionAmount: transactionAmount,
                        repartition: $repartition,
                        isRepartitionComplete: $isRepartitionComplete
                    )
                }
                if showRecurrence {
                    GroupBox(label: Text("Recurrence")) {
                        Text("Hello here")
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
                }
            }
            .padding()
        }
        .onAppear {
            repartition = Dictionary(
                uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) })
        }
    }
}

struct IncomeRepartitionView: View {
    var currency: Currency
    var transactionAmount: Int
        
    @Binding var repartition: [BudgetCategory: Int]
    @Binding var isRepartitionComplete: Bool
    
    var body: some View {
        GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
            VStack(alignment: .leading, spacing: .large) {
                Text("In which categories would you like to split this income?")
                IncomeRepartitionComponent(
                    repartition: $repartition,
                    amountToSplit: transactionAmount,
                    formatter: currency.roundFormatter,
                    isRepartitionComplete: $isRepartitionComplete
                )
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

#Preview {
    @Previewable @State var repartition = Dictionary(
        uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 100 / BudgetCategory.allCases.count) })
    @Previewable @State var isRepartitionComplete: Bool = false
    
    RepartitionRecurrenceView(
        currency: Currencies.currency(for: "EUR")!,
        transactionAmount: 1000,
        repartition: $repartition,
        isRepartitionComplete: $isRepartitionComplete,
        showRecurrence: true,
        showIncomeRepartition: true
    )
}
