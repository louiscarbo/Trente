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
    @State private var rowSelection = RowSelection<RecurringTransactionRule.ID>()

    private var selectedRules: [RecurringTransactionRule] {
        rowSelection.selected(in: rules)
    }

    private var activeRules: [RecurringTransactionRule] {
        rules.filter { !$0.hasEnded }
    }

    private var endedRules: [RecurringTransactionRule] {
        rules.filter(\.hasEnded)
    }

    var body: some View {
        List(selection: rowSelection.isActive ? $rowSelection.selectedIDs : nil) {
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
        .navigationTitle(rowSelection.isActive ? Text("\(selectedRules.count) Selected") : Text("Recurring Transactions"))
        .inlineNavigationBarTitleDisplayMode()
        .sheet(item: $selectedRule) { rule in
            RecurringTransactionRuleDetailsView(rule: rule, currency: currency)
        }
        .deleteConfirmation(item: $ruleToDelete) { rule in
            transactionActions.delete(rule, in: modelContext)
        }
        .selectionMode(
            $rowSelection,
            visibleIDs: rules.map(\.id),
            deleteTitle: String(localized: "Delete \(selectedRules.count) Recurring Transactions"),
            reviewSections: { reviewSections(for: selectedRules) },
            onDelete: deleteSelectedRules
        )
    }

    @ViewBuilder
    private func row(for rule: RecurringTransactionRule) -> some View {
        if rowSelection.isActive {
            summaryRow(for: rule)
        } else {
            Button {
                selectedRule = rule
            } label: {
                summaryRow(for: rule)
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
    }

    private func summaryRow(for rule: RecurringTransactionRule) -> some View {
        SummaryRow(
            title: rule.title,
            schedule: scheduleDescription(for: rule),
            amount: displayAmount(for: rule),
            isEnded: rule.hasEnded
        )
    }

    private func deleteSelectedRules() {
        transactionActions.delete(selectedRules, in: modelContext)
        rowSelection.end()
    }

    private func reviewSections(for rules: [RecurringTransactionRule]) -> [BatchDeleteReviewSheet.Section] {
        var sections: [BatchDeleteReviewSheet.Section] = [
            .willBeDeleted(rules.map { rule in .init(title: rule.title, detail: nextDateDescription(for: rule)) })
        ]

        let recordedRules = rules.filter { rule in !rule.transactions.isEmpty }
        if !recordedRules.isEmpty {
            sections.append(
                .stays(
                    recordedRules.map { rule in .init(title: rule.title, transactionCount: rule.transactions.count) },
                    note: String(localized: "Past transactions stay in their months with the same amounts.")
                )
            )
        }
        return sections
    }

    private func nextDateDescription(for rule: RecurringTransactionRule) -> String? {
        guard let date = rule.nextDateIfPending(onOrAfter: .now) else { return nil }
        let formattedDate = date.formatted(.dateTime.month(.abbreviated).day())
        return String(localized: "Next: \(formattedDate)")
    }

    private func scheduleDescription(for rule: RecurringTransactionRule) -> String {
        guard rule.hasEnded, let endDate = rule.endDate else { return rule.frequencyDescription }
        return String(localized: "Ended on \(endDate.formatted(.dateTime.day().month(.wide).year()))")
    }

    private func displayAmount(for rule: RecurringTransactionRule) -> String {
        (Double(rule.amountCents) / 100).formatted(.amount(currency.isoCode))
    }
}

#Preview {
    NavigationStack {
        RecurringTransactionsListView(currency: Month.month1.currency)
    }
    .modelContainer(DataProvider.shared.modelContainer)
}
