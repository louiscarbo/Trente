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
            VStack {
                if showIncomeRepartition {
                    GroupBox(label: Text("Income Repartition")) {
                        Text("Hello there")
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
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
