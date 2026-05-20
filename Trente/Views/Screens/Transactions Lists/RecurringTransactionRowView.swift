//
//  RecurringTransactionRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import SwiftUI
import WidgetKit

struct RecurringTransactionRowView: View {
    @Environment(\.modelContext) private var modelContext
    @State var instance: RecurringTransactionInstance
    @State var isInList = false
    @State private var showDetails = false
    @State private var ruleSaved = false

    private var validationState: ValidationState {
        if instance.confirmed { return .confirmed }
        let endOfToday = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_399)
        return instance.date <= endOfToday ? .pendingDue : .pendingUpcoming
    }

    var body: some View {
        Group {
            if instance.rule.repartition.keys.count > 1 {
                DisclosureGroup {
                    VStack {
                        if !isInList { Divider() }
                        ForEach(Array(instance.rule.repartition.keys), id: \.self) { category in
                            let amount = instance.rule.repartition[category] ?? 0
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
                    HStack {
                        RecurringTransactionEntryRowView(
                            transactionCategoryColor: .red,
                            transactionCategoryName: "Income",
                            currency: instance.month.currency,
                            displayAmount: instance.displayAmount,
                            title: instance.rule.title,
                            validationState: validationState
                        )
                        validateButton
                    }
                }

            } else if instance.rule.repartition.keys.count == 1 {
                let category = instance.rule.repartition.keys.first!
                Button { showDetails = true } label: {
                    HStack {
                        RecurringTransactionEntryRowView(
                            transactionCategoryColor: category.color,
                            transactionCategoryName: category.shortName,
                            currency: instance.month.currency,
                            displayAmount: instance.displayAmount,
                            title: instance.rule.title,
                            validationState: validationState
                        )
                        validateButton
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

            } else {
                EmptyView()
                    .onAppear {
                        print("WARNING: RecurringTransactionRowView: instance.rule.repartition is empty")
                    }
            }
        }
        .sheet(isPresented: $showDetails, onDismiss: {
            guard ruleSaved else { return }
            ruleSaved = false
            try? RecurringTransactionService.shared.refreshInstances(for: instance.rule, in: modelContext)
        }) {
            RecurringTransactionRuleDetailsView(
                rule: instance.rule,
                currency: instance.month.currency,
                onSave: { ruleSaved = true }
            )
        }
    }

    @ViewBuilder
    private var validateButton: some View {
        if !instance.confirmed, !instance.rule.autoConfirm {
            Button("Validate") {
                try? RecurringTransactionService.shared.validate(instance: instance, in: modelContext)
                WidgetCenter.shared.reloadAllTimelines()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .padding(.trailing, 4)
        }
    }

    private func formatAmount(_ amount: Int) -> String {
        (Double(amount) / 100.0).formatted(.currency(code: instance.month.currency.isoCode))
    }
}

private struct RecurringTransactionEntryRowView: View {
    @State var transactionCategoryColor: Color
    @State var transactionCategoryName: String
    @State var currency: Currency?
    @State var displayAmount: String
    @State var title: String?
    @State var validationState: ValidationState = .confirmed

    private var isAlone: Bool { currency != nil && title != nil }

    var body: some View {
        HStack {
            if isAlone {
                RecurrenceTagView(
                    color: transactionCategoryColor,
                    frequency: .monthly,
                    currency: currency!,
                    validationState: validationState
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
    var validationState: ValidationState = .confirmed

    private var tagColor: Color {
        validationState == .pendingDue ? .orange : color
    }

    private var tagLabel: String {
        validationState == .pendingDue
            ? String(localized: "To validate")
            : frequency.displayName
    }

    var body: some View {
        Text(tagLabel)
            .font(.subheadline)
            .tint(.primary)
            .padding(8)
            .background {
                Capsule()
                    .fill(tagColor.opacity(0.1))
                    .stroke(tagColor.secondary, lineWidth: 2)
            }
    }
}

#Preview {
    Text("Recurring Transaction Row View")

    ScrollView {
        LazyVStack {
            ForEach(Month.month1.recurringTransactionInstances) { recurringTransactionInstance in
                RecurringTransactionRowView(instance: recurringTransactionInstance)
            }
        }
        .padding()
    }
}
