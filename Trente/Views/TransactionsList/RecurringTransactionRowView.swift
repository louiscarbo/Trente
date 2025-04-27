//
//  RecurringTransactionRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import SwiftUI

struct RecurringTransactionRowView: View {
    @State var instance: RecurringTransactionInstance
    @State var isInList = false
    
    var body: some View {
        if instance.rule.repartition.keys.count > 1 {
            DisclosureGroup {
                VStack {
                    if !isInList {
                        Divider()
                    }
                    ForEach(Array(instance.rule.repartition.keys), id: \.self) { category in
                        let amount = instance.rule.repartition[category] ?? 0
                        
                        RecurringTransactionEntryRowView(
                            transactionCategoryColor: category.color,
                            transactionCategoryName: category.shortName,
                            displayAmount: formatAmount(amount)
                        )
                    }
                }
                .padding(.leading)
                
            } label: {
                RecurringTransactionEntryRowView(
                    transactionCategoryColor: .red,
                    transactionCategoryName: "Income",
                    currency: instance.month.currency,
                    displayAmount: instance.displayAmount,
                    title: instance.rule.title
                )
            }
        } else if instance.rule.repartition.keys.count == 1 {
            let category = instance.rule.repartition.keys.first!
            RecurringTransactionEntryRowView(
                transactionCategoryColor: category.color,
                transactionCategoryName: category.shortName,
                currency: instance.month.currency,
                displayAmount: instance.displayAmount,
                title: instance.rule.title
            )
        } else {
            EmptyView()
                .onAppear {
                    print("WARNING: RecurringTransactionRowView: instance.rule.repartition is empty")
                }
        }
    }
    
    private func formatAmount(_ amount: Int) -> String {
        let amount = Double(amount) / 100.0
        return amount.formatted(.currency(code: instance.month.currency.isoCode))
    }
}

private struct RecurringTransactionEntryRowView: View {
    @State var transactionCategoryColor: Color
    @State var transactionCategoryName: String
    @State var currency: Currency?
    @State var displayAmount: String
    @State var title: String? = nil
    
    private var isAlone: Bool {
        return currency != nil && title != nil
    }
    
    var body: some View {
        HStack {
            if isAlone {
                RecurrenceView(
                    color: transactionCategoryColor,
                    frequency: .monthly,
                    currency: currency!
                )
            } else {
                Circle()
                    .fill(transactionCategoryColor)
                    .frame(width: 10, height: 10)
                    .padding(4)
            }
            
            VStack(alignment: .leading) {
                if isAlone {
                    Text(title!)
                        .font(.headline)
                }
                Text(transactionCategoryName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .tint(isAlone ? .primary : .secondary)
            
            Spacer()
            Text(displayAmount)
                .font(isAlone ? .title : .subheadline)
                .foregroundStyle(isAlone ? .primary : .secondary)
                .tint(isAlone ? .primary : .secondary)
        }
    }
}

private struct RecurrenceView: View {
    var color: Color
    var frequency: RecurrenceFrequency
    var currency: Currency
    
    var body: some View {
        Text(frequency.displayName)
            .font(.subheadline)
            .tint(.primary)
            .padding(8)
            .background {
                Capsule()
                    .fill(color.opacity(0.1))
                    .stroke(color.secondary, lineWidth: 2)
            }
    }
}

#Preview {
    Text("Recurring Transaction Row View")
        .modelContainer(DataProvider.shared.modelContainer)
    
    ScrollView {
        LazyVStack {
            ForEach(Month.month1.recurringTransactionInstances) { recurringTransactionInstance in
                
                RecurringTransactionRowView(instance: recurringTransactionInstance)
            }
        }
        .padding()
    }
}
