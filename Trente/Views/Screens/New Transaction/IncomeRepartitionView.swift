//
//  RepartitionRecurrenceView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI

struct IncomeRepartitionView: View {
    // Transaction Data
    let currency: Currency
    var transactionAmount: Int
    @Binding var repartition: [BudgetCategory: Int]
    
    // View State
    @Binding var isRepartitionComplete: Bool
        
    var body: some View {
        ScrollView {
            VStack(spacing: .large) {
                GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
                    VStack(alignment: .leading, spacing: .large) {
                        Text("How would you like to split this income?")
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
            .padding()
        }
        .onAppear {
            repartition = Dictionary(
                uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) })
        }
    }
}

#Preview {
    @Previewable @State var repartition = Dictionary(
        uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 100 / BudgetCategory.allCases.count) })
    @Previewable @State var isRepartitionComplete: Bool = false
    
    IncomeRepartitionView(
        currency: Currencies.currency(for: "EUR")!,
        transactionAmount: 1000,
        repartition: $repartition,
        isRepartitionComplete: $isRepartitionComplete
    )
}
