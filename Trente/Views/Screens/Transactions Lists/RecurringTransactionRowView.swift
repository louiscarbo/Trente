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

    @State private var showPaymentSheet = false
    @State private var showConfirmConfirmation = false
    @State private var showSkipConfirmation = false

    var body: some View {
        Button {
            showPaymentSheet = true
        } label: {
            RecurringOccurrenceRowContent(
                title: occurrence.rule.title,
                date: occurrence.date,
                categoryName: occurrence.categoryName,
                frequency: occurrence.rule.frequency,
                amount: Double(occurrence.amountCents) / 100,
                currencyCode: occurrence.month.currency.isoCode,
                isOverdue: occurrence.isOverdue
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button {
                showConfirmConfirmation = true
            } label: {
                Label(
                    occurrence.isIncome ? String(localized: "Received") : String(localized: "Paid"),
                    systemImage: "checkmark.circle"
                )
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showSkipConfirmation = true
            } label: {
                Label("Skip", systemImage: "forward.end")
            }
            .tint(.gray)
        }
        .contextMenu {
            Button {
                showConfirmConfirmation = true
            } label: {
                Label(
                    occurrence.isIncome ? String(localized: "Received") : String(localized: "Paid"),
                    systemImage: "checkmark.circle"
                )
            }
            Button {
                showSkipConfirmation = true
            } label: {
                Label("Skip", systemImage: "forward.end")
            }
        }
        .confirmationDialog(
            confirmConfirmationTitle,
            isPresented: $showConfirmConfirmation,
            titleVisibility: .visible
        ) {
            Button(occurrence.isIncome ? String(localized: "Mark as Received") : String(localized: "Mark as Paid")) {
                transactionActions.confirm(occurrence, in: modelContext)
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text("It's added to this month's transactions.")
        }
        .skipOccurrenceConfirmation(
            isPresented: $showSkipConfirmation,
            title: occurrence.rule.title,
            date: occurrence.date,
            frequency: occurrence.rule.frequency
        ) {
            transactionActions.skip(occurrence, in: modelContext)
        }
        .sheet(isPresented: $showPaymentSheet) {
            RecurringOccurrenceSheet(occurrence: occurrence)
        }
        .clipShape(Rectangle().inset(by: -3))
    }

    private var confirmConfirmationTitle: String {
        let title = occurrence.rule.title
        return occurrence.isIncome
            ? String(localized: "Mark \(title) as received?")
            : String(localized: "Mark \(title) as paid?")
    }
}

private struct RecurringOccurrenceRowContent: View {
    let title: String
    let date: Date
    let categoryName: String
    let frequency: RecurrenceFrequency
    let amount: Double
    let currencyCode: String
    let isOverdue: Bool

    var body: some View {
        HStack(spacing: 12) {
            OccurrenceDateBadge(date: date, isOverdue: isOverdue)
            VStack(alignment: .leading) {
                Text(title)
                    .multilineTextAlignment(.leading)
                    .font(.headline)
                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amount, format: .currency(code: currencyCode))
                .font(.title2)
        }
    }

    private var subtitle: Text {
        guard isOverdue else {
            return Text("\(categoryName) · \(frequency.displayName)")
        }
        return Text("\(Text("Overdue").foregroundStyle(.orange)) · \(categoryName)")
    }
}

private struct OccurrenceDateBadge: View {
    let date: Date
    let isOverdue: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.day())
                .font(.title3.weight(.semibold))
                .foregroundStyle(isOverdue ? Color.orange : Color.primary)
            Text(date, format: .dateTime.month(.abbreviated))
                .font(.caption2)
                .textCase(.uppercase)
                .foregroundStyle(isOverdue ? Color.orange : Color.secondary)
        }
        .frame(width: 36)
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
                RecurringTransactionRowView(occurrence: occurrence)
                Divider()
            }
        }
        .padding()
    }
}
