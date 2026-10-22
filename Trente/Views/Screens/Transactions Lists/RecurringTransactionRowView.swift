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

    @State private var showPaymentSheet = false
    @State private var showConfirmConfirmation = false
    @State private var showSkipConfirmation = false

    var body: some View {
        Button {
            showPaymentSheet = true
        } label: {
            RecurringOccurrenceRowContent(occurrence: occurrence)
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
        .confirmationDialog(
            confirmConfirmationTitle,
            isPresented: $showConfirmConfirmation,
            titleVisibility: .visible
        ) {
            Button(occurrence.isIncome ? String(localized: "Mark as Received") : String(localized: "Mark as Paid")) {
                try? RecurringTransactionService.shared.confirm(occurrence, in: modelContext)
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text("It's added to this month's transactions.")
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
}

private struct RecurringOccurrenceRowContent: View {
    let occurrence: RecurringTransactionOccurrence

    var body: some View {
        HStack(spacing: 12) {
            OccurrenceDateBadge(date: occurrence.date, isOverdue: occurrence.isOverdue)
            VStack(alignment: .leading) {
                Text(occurrence.rule.title)
                    .multilineTextAlignment(.leading)
                    .font(.headline)
                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(occurrence.displayAmount)
                .font(.title2)
        }
    }

    private var subtitle: Text {
        guard occurrence.isOverdue else {
            return Text("\(occurrence.categoryName) · \(occurrence.rule.frequency.displayName)")
        }
        return Text("\(Text("Overdue").foregroundStyle(.orange)) · \(occurrence.categoryName)")
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
