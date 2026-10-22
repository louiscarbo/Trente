//
//  RecurringTransactionRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import SwiftUI

struct RecurringTransactionRowView: View {
    @Environment(\.modelContext) private var modelContext
    let occurrence: RecurringTransactionOccurrence
    @State var isInList = false
    @State private var showDetails = false
    @State private var editFromSwipe = false
    @State private var showSkipConfirmation = false
    @State private var showValidateConfirmation = false

    var body: some View {
        Group {
            if occurrence.rule.repartition.keys.count > 1 {
                DisclosureGroup {
                    VStack {
                        if !isInList {
                            Divider()
                        }
                        ForEach(Array(occurrence.rule.repartition.keys), id: \.self) { category in
                            let amount = occurrence.rule.repartition[category] ?? 0

                            Button { showDetails = true } label: {
                                RecurringTransactionEntryRowView(
                                    transactionCategoryColor: category.color,
                                    transactionCategoryName: category.shortName,
                                    displayAmount: formatAmount(amount)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.leading)

                } label: {
                    RecurringTransactionEntryRowView(
                        transactionCategoryColor: .red,
                        transactionCategoryName: "Income",
                        currency: occurrence.month.currency,
                        displayAmount: occurrence.displayAmount,
                        title: occurrence.rule.title
                    )
                }
            } else if occurrence.rule.repartition.keys.count == 1 {
                let category = occurrence.rule.repartition.keys.first!
                Button { showDetails = true } label: {
                    RecurringTransactionEntryRowView(
                        transactionCategoryColor: category.color,
                        transactionCategoryName: category.shortName,
                        currency: occurrence.month.currency,
                        displayAmount: occurrence.displayAmount,
                        title: occurrence.rule.title
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                EmptyView()
                    .onAppear {
                        print("WARNING: RecurringTransactionRowView: occurrence.rule.repartition is empty")
                    }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showSkipConfirmation = true
            } label: {
                Label("Skip", systemImage: "forward.end")
            }
            .tint(.gray)
            Button {
                editFromSwipe = true
                showDetails = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading) {
            Button {
                showValidateConfirmation = true
            } label: {
                Label("Validate", systemImage: "checkmark.circle")
            }
            .tint(.green)
        }
        .confirmationDialog(
            skipConfirmationTitle,
            isPresented: $showSkipConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Skip")) {
                try? RecurringTransactionService.shared.skip(occurrence, in: modelContext)
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text("Only this one is skipped. The next ones stay planned.")
        }
        .confirmationDialog(
            String(localized: "Confirm this transaction?"),
            isPresented: $showValidateConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Confirm")) {
                try? RecurringTransactionService.shared.confirm(occurrence, in: modelContext)
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text("This adds it as a transaction for this month.")
        }
        .sheet(isPresented: $showDetails) {
            RecurringTransactionRuleDetailsView(
                rule: occurrence.rule,
                currency: occurrence.month.currency,
                startInEditMode: editFromSwipe
            )
        }
        .onChange(of: showDetails) { _, isShowing in
            if !isShowing { editFromSwipe = false }
        }
        .clipShape(Rectangle().inset(by: -3))
    }

    private var skipConfirmationTitle: String {
        let title = occurrence.rule.title
        switch occurrence.rule.frequency {
        case .weekly:
            return String(localized: "Skip \(title) this week?")
        case .monthly:
            return String(localized: "Skip \(title) this month?")
        case .yearly:
            return String(localized: "Skip \(title) this year?")
        }
    }

    private func formatAmount(_ amount: Int) -> String {
        let amount = Double(amount) / 100.0
        return amount.formatted(.currency(code: occurrence.month.currency.isoCode))
    }
}

private struct RecurringTransactionEntryRowView: View {
    @State var transactionCategoryColor: Color
    @State var transactionCategoryName: String
    @State var currency: Currency?
    @State var displayAmount: String
    @State var title: String?
    
    private var isAlone: Bool {
        return currency != nil && title != nil
    }
    
    var body: some View {
        HStack {
            if isAlone {
                RecurrenceTagView(
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

private struct RecurrenceTagView: View {
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
    
    ScrollView {
        LazyVStack {
            ForEach(
                RecurringTransactionService.shared.pendingOccurrences(of: RecurringTransactionRule.sampleData, in: Month.month1)
            ) { occurrence in
                RecurringTransactionRowView(occurrence: occurrence)
            }
        }
        .padding()
    }
}
