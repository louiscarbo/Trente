//
//  PendingTransactionRow.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftUI

struct PendingTransactionRow: View {
    let title: String
    let date: Date
    let amount: Double
    let currencyCode: String
    let showsActionButtons: Bool
    let onReview: () -> Void
    let onDiscard: () -> Void

    @State private var isConfirmingDiscard = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
            Button(action: onReview) {
                HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                    RecurringTransactionRowView.DateBadge(date: date, isOverdue: false)
                    VStack(alignment: .leading) {
                        Text(title)
                            .multilineTextAlignment(.leading)
                            .font(.headline)
                        Text(amount, format: .amount(currencyCode))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if showsActionButtons {
                actionButton("Discard", systemImage: "xmark") {
                    isConfirmingDiscard = true
                }
                .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
                actionButton("Review", systemImage: "checkmark", action: onReview)
                    .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
            }
        }
        .rowActions(
            leading: RowAction(
                title: String(localized: "Review"),
                systemImage: "checkmark.circle",
                tint: .green,
                action: onReview
            ),
            trailing: RowAction(
                title: String(localized: "Discard"),
                systemImage: "xmark",
                tint: .red,
                isDestructive: true
            ) {
                isConfirmingDiscard = true
            }
        )
        .confirmationDialog(
            "Discard \(title)?",
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive, action: onDiscard)
        }
    }

    private func actionButton(
        _ title: LocalizedStringKey,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .padding(.vertical, 3)
        }
        .frame(width: 48)
    }
}

#Preview {
    PendingTransactionRow(
        title: "Café Lumière",
        date: .now,
        amount: -4.20,
        currencyCode: "EUR",
        showsActionButtons: true,
        onReview: {},
        onDiscard: {}
    )
    .padding()
}
