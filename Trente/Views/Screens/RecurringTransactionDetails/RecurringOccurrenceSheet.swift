//
//  RecurringOccurrenceSheet.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/10/2026.
//

import SwiftData
import SwiftUI

struct RecurringOccurrenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let occurrence: RecurringTransactionOccurrence

    @State private var showRecurringTransaction = false
    @State private var showSkipConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .medium) {
                    summaryBox
                    actionButtons
                    recurringTransactionBox
                }
                .padding()
            }
            .navigationTitle(occurrence.rule.title)
            .inlineNavigationBarTitleDisplayMode()
            .toolbar {
                CloseToolbarItem { dismiss() }
            }
            .errorAlert(message: $errorMessage)
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showRecurringTransaction) {
            RecurringTransactionRuleDetailsView(
                rule: occurrence.rule,
                currency: occurrence.month.currency
            )
        }
    }

    private var summaryBox: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: .small) {
                Text(dueDescription)
                    .font(.subheadline)
                    .foregroundStyle(occurrence.isOverdue ? Color.orange : Color.secondary)
                Text(Double(occurrence.amountCents) / 100, format: .amount(occurrence.month.currency.isoCode))
                    .font(.largeTitle.weight(.semibold))
                ForEach(splitCategories, id: \.self) { category in
                    HStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 10, height: 10)
                        Text(category.name)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if splitCategories.count > 1 {
                            Text(displayAmount(for: category))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }

    private var actionButtons: some View {
        HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
            Button(action: confirm) {
                Label(
                    occurrence.isIncome ? String(localized: "Mark as Received") : String(localized: "Mark as Paid"),
                    systemImage: "checkmark.circle.fill"
                )
                .labelStyle(.centeredIcon)
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxHeight: .infinity)
            }
            .buttonStyle(TrentePrimaryButtonStyle(narrow: true))

            Button {
                showSkipConfirmation = true
            } label: {
                Label(skipTitle, systemImage: "forward.end.fill")
                    .labelStyle(.centeredIcon)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: .infinity)
            }
            .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
            .skipOccurrenceConfirmation(
                isPresented: $showSkipConfirmation,
                title: occurrence.rule.title,
                date: occurrence.date,
                frequency: occurrence.rule.frequency,
                onSkip: skip
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var recurringTransactionBox: some View {
        GroupBox(label: Label("Schedule", systemImage: "clock.arrow.circlepath")) {
            Button {
                showRecurringTransaction = true
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(occurrence.rule.frequencyDescription)
                            .font(.headline)
                        Text("Change or stop this schedule")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }

    private var dueDescription: String {
        let day = occurrence.date.formatted(.dateTime.day().month(.wide))
        if occurrence.isOverdue {
            return String(localized: "Overdue since \(day)")
        }
        if Calendar.current.isDateInToday(occurrence.date) {
            return String(localized: "Due today")
        }
        return String(localized: "Due \(day)")
    }

    private var skipTitle: String {
        switch occurrence.rule.frequency {
        case .weekly:
            String(localized: "Skip This Week")
        case .monthly:
            String(localized: "Skip This Month")
        case .yearly:
            String(localized: "Skip This Year")
        }
    }

    private var splitCategories: [BudgetCategory] {
        BudgetCategory.allCases.filter { (occurrence.rule.repartition[$0] ?? 0) != 0 }
    }

    private func displayAmount(for category: BudgetCategory) -> String {
        let cents = occurrence.rule.repartition[category] ?? 0
        return (Double(cents) / 100.0).formatted(.amount(occurrence.month.currency.isoCode))
    }

    private func confirm() {
        do {
            try RecurringTransactionService.shared.confirm(occurrence, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func skip() {
        do {
            try RecurringTransactionService.shared.skip(occurrence, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    let month = Month.month1
    let rule = RecurringTransactionRule.sampleData[0]

    RecurringOccurrenceSheet(
        occurrence: RecurringTransactionOccurrence(rule: rule, date: month.startDate, month: month)
    )
}
