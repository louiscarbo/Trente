//
//  RecurringTransactionsListView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI
import SwiftData

struct RecurringTransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.transactionActions) private var transactionActions

    let currency: Currency

    @Query(sort: \RecurringTransactionRule.title) private var rules: [RecurringTransactionRule]
    @State private var selectedRule: RecurringTransactionRule?
    @State private var ruleToDelete: RecurringTransactionRule?

    private var activeRules: [RecurringTransactionRule] {
        rules.filter { !$0.hasEnded }
    }

    private var endedRules: [RecurringTransactionRule] {
        rules.filter(\.hasEnded)
    }

    var body: some View {
        List {
            if !activeRules.isEmpty {
                Section("Active") {
                    ForEach(activeRules) { rule in
                        row(for: rule)
                    }
                }
            }
            if !endedRules.isEmpty {
                Section("Ended") {
                    ForEach(endedRules) { rule in
                        row(for: rule)
                    }
                }
            }
        }
        .overlay {
            if rules.isEmpty {
                ContentUnavailableView(
                    "No Recurring Transactions",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Turn on \"Recurring transaction\" when you add a transaction.")
                )
            }
        }
        .navigationTitle("Recurring Transactions")
        .sheet(item: $selectedRule) { rule in
            RecurringTransactionRuleDetailsView(rule: rule, currency: currency)
        }
        .deleteConfirmation(isPresented: $ruleToDelete.isPresent()) {
            guard let ruleToDelete else { return }
            transactionActions.delete(ruleToDelete, in: modelContext)
        }
    }

    private func row(for rule: RecurringTransactionRule) -> some View {
        Button {
            selectedRule = rule
        } label: {
            RecurringTransactionSummaryRow(
                title: rule.title,
                schedule: scheduleDescription(for: rule),
                amount: displayAmount(for: rule),
                isEnded: rule.hasEnded
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                ruleToDelete = rule
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func scheduleDescription(for rule: RecurringTransactionRule) -> String {
        guard rule.hasEnded, let endDate = rule.endDate else { return rule.frequencyDescription }
        return String(localized: "Ended on \(endDate.formatted(.dateTime.day().month(.wide).year()))")
    }

    private func displayAmount(for rule: RecurringTransactionRule) -> String {
        (Double(rule.amountCents) / 100).formatted(.currency(code: currency.isoCode))
    }
}

private struct RecurringTransactionSummaryRow: View {
    let title: String
    let schedule: String
    let amount: String
    let isEnded: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(schedule)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amount)
                .font(.title3)
        }
        .opacity(isEnded ? 0.5 : 1)
    }
}

#Preview {
    NavigationStack {
        RecurringTransactionsListView(currency: Month.month1.currency)
    }
    .modelContainer(DataProvider.shared.modelContainer)
}
