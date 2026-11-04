//
//  RecurringTransactionRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import SwiftData
import SwiftUI

struct RecurringTransactionRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.transactionActions) private var transactionActions
    let occurrence: RecurringTransactionOccurrence
    var showsDateBadge = true
    let onOpen: () -> Void

    @State private var showSkipConfirmation = false

    var body: some View {
        Button(action: onOpen) {
            OccurrenceContent(
                title: occurrence.rule.title,
                date: occurrence.date,
                categoryName: occurrence.categoryName,
                frequency: occurrence.rule.frequency,
                amount: Double(occurrence.amountCents) / 100,
                currencyCode: occurrence.month.currency.isoCode,
                isOverdue: occurrence.isOverdue,
                isDueToday: occurrence.isDueToday,
                showsDateBadge: showsDateBadge
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .rowActions(
            leading: RowAction(
                title: occurrence.isIncome ? String(localized: "Received") : String(localized: "Paid"),
                systemImage: "checkmark.circle",
                tint: .green,
                allowsFullSwipe: false
            ) {
                transactionActions.confirm(occurrence, in: modelContext)
            },
            trailing: RowAction(
                title: String(localized: "Skip"),
                systemImage: "forward.end",
                tint: .gray
            ) {
                showSkipConfirmation = true
            }
        )
        .skipOccurrenceConfirmation(
            isPresented: $showSkipConfirmation,
            title: occurrence.rule.title,
            date: occurrence.date,
            frequency: occurrence.rule.frequency
        ) {
            transactionActions.skip(occurrence, in: modelContext)
        }
    }
}

#Preview {
    let month = Month.month1
    let occurrences = RecurringTransactionRule.sampleData.enumerated().map { index, rule in
        RecurringTransactionOccurrence(
            rule: rule,
            date: Calendar.current.date(byAdding: .day, value: index * 4 - 4, to: .now)!,
            month: month
        )
    }

    ScrollView {
        LazyVStack {
            ForEach(occurrences) { occurrence in
                RecurringTransactionRowView(occurrence: occurrence) {}
                Divider()
            }
        }
        .padding()
    }
}
