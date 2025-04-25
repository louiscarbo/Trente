//
//  RecurringTransactionRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import SwiftUI

struct RecurringTransactionRowView: View {
    @State var recurringTransactionInstance: RecurringTransactionInstance
    
    var body: some View {
        HStack {
            Circle()
                .fill(recurringTransactionInstance.confirmed ? recurringTransactionInstance.rule.category.color : .clear)
                .stroke(recurringTransactionInstance.confirmed ? .clear : recurringTransactionInstance.rule.category.color, lineWidth: 2)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                Text(recurringTransactionInstance.rule.title)
                    .font(.headline)
                Text("On **\(recurringTransactionInstance.displayDate)**")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: recurringTransactionInstance.month.currency.sfSymbolRecurrenceName)
                        .font(.subheadline)
                    Text(recurringTransactionInstance.rule.frequencyDescription)
                        .font(.subheadline)
                }
                .padding(7)
                .background {
                    Capsule()
                        .fill(.thickMaterial)
                        .stroke(.primary.opacity(0.2), lineWidth: 2)
                }
            }
            Spacer()
            Text(recurringTransactionInstance.displayAmount)
                .font(.title)
        }
    }
}

#Preview {
    Text("Recurring Transaction Row View")
        .modelContainer(SampleDataProvider.shared.modelContainer)
    
    ScrollView {
        LazyVStack {
            ForEach(Month.month1.recurringTransactionInstances) { recurringTransactionInstance in
                
                RecurringTransactionRowView(recurringTransactionInstance: recurringTransactionInstance)
            }
        }
        .padding()
    }
}
