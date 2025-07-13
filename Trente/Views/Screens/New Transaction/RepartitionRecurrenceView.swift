//
//  RepartitionRecurrenceView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI

struct RepartitionRecurrenceView: View {
    // Transaction Data
    
    // View State
    @State var showRecurrence: Bool
    @State var showIncomeRepartition: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: .large) {
                if showIncomeRepartition {
                    IncomeRepartitionView()
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
    }
}

struct IncomeRepartitionView: View {
    @State var repartition: [BudgetCategory: Int] = Dictionary(
        uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 100 / BudgetCategory.allCases.count) })
    
    var body: some View {
        GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
            VStack(spacing: .small) {
                Text("In which categories would you like to split this income?")
                IncomeRepartitionComponent(repartition: $repartition, amountToSplit: 100, categories: BudgetCategory.allCases)
            }
            .padding()
            
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

#Preview {
    RepartitionRecurrenceView(showRecurrence: true, showIncomeRepartition: true)
}
