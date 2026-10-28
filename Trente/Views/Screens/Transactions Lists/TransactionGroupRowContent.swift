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
    let title: String
    let amount: Double
    let currencyCode: String

    var body: some View {
        HStack {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text("Income")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amount, format: .amount(currencyCode))
                .font(.title)
        }
        .tint(.primary)
    }
}

/// A single entry row: category dot, optional group title, category name and amount.
struct TransactionEntryRowContent: View {
    let category: BudgetCategory
    let amount: Double
    let currencyCode: String
    var title: String?

    var body: some View {
        HStack {
            Circle()
                .fill(category.color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                if let title {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .font(.headline)
                }
                ViewThatFits(in: .horizontal) {
                    Text(category.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(category.shortName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(amount, format: .amount(currencyCode))
                .font(title == nil ? .subheadline : .title)
                .foregroundStyle(title == nil ? .secondary : .primary)
        }
    }
}

/// Read-only rendering of a whole group, branching on entry count.
/// Used by the widget; the app uses an interactive disclosure instead.
struct TransactionGroupRowContent: View {
    let title: String
    let categories: [BudgetCategory]
    let amount: Double
    let currencyCode: String

    var body: some View {
        if categories.count > 1 {
            TransactionGroupSummaryRow(title: title, amount: amount, currencyCode: currencyCode)
        } else if let category = categories.first {
            TransactionEntryRowContent(
                category: category,
                amount: amount,
                currencyCode: currencyCode,
                title: title
            )
        } else {
            EmptyView()
        }
    }
}
