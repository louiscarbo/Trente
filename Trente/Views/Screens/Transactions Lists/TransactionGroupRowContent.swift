//
//  TransactionGroupRowContent.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/06/2026.
//

import SwiftUI

// Presentational, read-only rendering of a transaction group row.
// Shared by the app (wrapped with swipe actions and a detail sheet in
// TransactionGroupRowView) and by the widget (used directly, no interactivity).
// Keep this file free of app-only dependencies so it stays in the widget target.

/// Summary row for a multi-entry income group: title and total amount.
struct TransactionGroupSummaryRow: View {
    let transactionGroup: TransactionGroup

    var body: some View {
        HStack {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                Text(transactionGroup.title)
                    .font(.headline)
                Text("Income")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(transactionGroup.displayAmount)
                .font(.title)
        }
        .tint(.primary)
    }
}

/// A single entry row: category dot, optional group title, category name and amount.
struct TransactionEntryRowContent: View {
    let transactionEntry: TransactionEntry
    var title: String?

    var body: some View {
        HStack {
            Circle()
                .fill(transactionEntry.category.color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                if let title {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .font(.headline)
                }
                ViewThatFits(in: .horizontal) {
                    Text(transactionEntry.category.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(transactionEntry.category.shortName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(transactionEntry.displayAmount)
                .font(title == nil ? .subheadline : .title)
                .foregroundStyle(title == nil ? .secondary : .primary)
        }
    }
}

/// Read-only rendering of a whole group, branching on entry count.
/// Used by the widget; the app uses an interactive disclosure instead.
struct TransactionGroupRowContent: View {
    let transactionGroup: TransactionGroup

    var body: some View {
        if transactionGroup.entries.count > 1 {
            TransactionGroupSummaryRow(transactionGroup: transactionGroup)
        } else if transactionGroup.entries.count == 1 {
            TransactionEntryRowContent(
                transactionEntry: transactionGroup.entries[0],
                title: transactionGroup.title
            )
        } else {
            EmptyView()
        }
    }
}
