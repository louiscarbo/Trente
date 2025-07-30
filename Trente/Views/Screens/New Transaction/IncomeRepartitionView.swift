//
//  IncomeRepartitionView.swift
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
    @Binding var nextButtonDisabled: Bool
        
    var body: some View {
        ScrollView {
            GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
                VStack(alignment: .leading, spacing: .large) {
                    Text("How would you like to split this income?")
                    IncomeRepartitionComponent(
                        repartition: $repartition,
                        amountToSplit: transactionAmount,
                        formatter: currency.roundFormatter,
                        isRepartitionComplete: Binding<Bool>(
                            get: {
                                true
                            }, set: {
                                nextButtonDisabled = !$0
                            }
                        )
                    )
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
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
    @Previewable @State var nextButtonDisabled: Bool = false
    
    IncomeRepartitionView(
        currency: Currencies.currency(for: "EUR")!,
        transactionAmount: 1000,
        repartition: $repartition,
        nextButtonDisabled: $nextButtonDisabled
    )
}
