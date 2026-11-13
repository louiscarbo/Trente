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
    @Binding var isRepartitionComplete: Bool
    var prefilledMonthName: String?

    var body: some View {
        ScrollView {
            VStack(spacing: .medium) {
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

                if let prefilledMonthName {
                    prefilledNote(monthName: prefilledMonthName)
                }
            }
            .padding()
        }
    }

    private func prefilledNote(monthName: String) -> some View {
        Label {
            Text("Pre-filled with your \(monthName) split. Adjust it if you need.")
                .font(.footnote)
        } icon: {
            Image(systemName: "sparkles")
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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
        isRepartitionComplete: $isRepartitionComplete,
        prefilledMonthName: "December"
    )
}
