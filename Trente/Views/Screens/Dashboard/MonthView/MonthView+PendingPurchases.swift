//
//  MonthView+PendingPurchases.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftUI
import SwiftData

extension MonthView {
    enum PendingReview: Hashable, Identifiable {
        case all
        case purchase(UUID)

        var id: Self { self }
    }

    struct PendingPurchases: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.transactionActions) private var transactionActions
        @Environment(\.isTrentePlusSubscribed) private var isTrentePlusSubscribed

        let pendingTransactions: [PendingTransaction]
        let currencyCode: String
        let onReview: (PendingReview) -> Void

        static func rowCount(forPendingCount pendingCount: Int) -> Int {
            pendingCount > 2 ? 1 : pendingCount
        }

        private var shownTransactions: ArraySlice<PendingTransaction> {
            pendingTransactions.prefix(Self.rowCount(forPendingCount: pendingTransactions.count))
        }

        private var hiddenTransactions: ArraySlice<PendingTransaction> {
            pendingTransactions.dropFirst(shownTransactions.count)
        }

        private var isAtFreeLimit: Bool {
            !WalletIntakeAllowance().allowsIntake(on: .now, isTrentePlusSubscribed: isTrentePlusSubscribed)
        }

        var body: some View {
            GroupBox(label: Label("\(pendingTransactions.count) Purchases to Review", systemImage: "list.clipboard")) {
                ForEach(shownTransactions) { pending in
                    PendingTransactionRow(
                        title: pending.title,
                        date: pending.date,
                        amount: Double(pending.amountCents) / 100,
                        currencyCode: currencyCode,
                        showsActionButtons: false,
                        onReview: { onReview(.purchase(pending.id)) },
                        onDiscard: { transactionActions.discard(pending, in: modelContext) }
                    )
                    .accessibilityHidden(isAtFreeLimit)

                    if pending != shownTransactions.last {
                        Divider()
                    }
                }

                if !hiddenTransactions.isEmpty {
                    moreButton
                        .accessibilityHidden(isAtFreeLimit)
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
            .overlay {
                if isAtFreeLimit {
                    Button {
                        onReview(.all)
                    } label: {
                        Color.clear
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Unlimited Apple Pay logging with Trente+")
                }
            }
        }

        private var moreButton: some View {
            Button {
                onReview(.all)
            } label: {
                HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(hiddenTransactions.count) more…")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(verbatim: hiddenTitles)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Text(hiddenAmount, format: .amount(currencyCode))
                        .font(.title2)
                        .fontWeight(.regular)
                }
                .padding(.horizontal)
            }
            .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
        }

        var hiddenTitles: String {
            hiddenTransactions.map(\.title).joined(separator: ", ")
        }

        var hiddenAmount: Double {
            Double(hiddenTransactions.map(\.amountCents).reduce(0, +)) / 100
        }
    }
}
