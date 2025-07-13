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
            VStack(spacing: DesignSystem.Spacing.medium.rawValue) {
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
    var body: some View {
        GroupBox(label: Text("Income Repartition")) {
            VStack(spacing: .small) {
                Text("In which categories would you like to split this income?")
                
                ForEach(BudgetCategory.allCases, id: \.self) { category in
                    HStack {
                        Text("-")
                            .background {
                                RoundedRectangle(cornerRadius: .large)
                                    .fill(category.color.opacity(0.3))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: .large)
                                    .stroke(category.color, lineWidth: 2)
                            }
                        Text(category.name)
                        Text("+")
                            .background {
                                RoundedRectangle(cornerRadius: .large)
                                    .fill(category.color.opacity(0.3))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: .large)
                                    .stroke(category.color, lineWidth: 2)
                            }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: .large)
                            .fill(category.color.opacity(0.3))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: .large)
                            .stroke(category.color, lineWidth: 2)
                    }
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

#Preview {
    RepartitionRecurrenceView(showRecurrence: true, showIncomeRepartition: true)
}
