//
//  PendingTransactionsListView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftUI
import SwiftData

struct PendingTransactionsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isTrentePlusSubscribed) private var isTrentePlusSubscribed
    @Query(sort: \PendingTransaction.date, order: .reverse, animation: .default)
    private var pendingTransactions: [PendingTransaction]

    let currencyCode: String

    @State private var reviewedID: UUID?
    @State private var discardError: String?
    private let allowance = WalletIntakeAllowance()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if isAtFreeLimit {
                        lockedRows
                    } else {
                        ForEach(pendingTransactions, content: row)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium.rawValue) {
                        Text("Not in your totals yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if !isTrentePlusSubscribed {
                            PendingTransactionReviewView.AllowanceNote(
                                loggedCount: min(allowance.count(on: .now), WalletIntakeAllowance.freeMonthlyLimit),
                                limit: WalletIntakeAllowance.freeMonthlyLimit
                            )
                        }
                    }
                }
            }
            .navigationTitle("To Review")
            .inlineNavigationBarTitleDisplayMode()
            .toolbar {
                CloseToolbarItem { dismiss() }
            }
        }
        .presentationDetents([.medium, .large])
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 360)
        #endif
        .sheet(isPresented: $reviewedID.isPresent()) {
            if let reviewedID {
                PendingTransactionReviewLoader(id: reviewedID)
                    .id(reviewedID)
            }
        }
        .errorAlert("Delete Failed", message: $discardError)
        .onChange(of: pendingTransactions.isEmpty) { _, isEmpty in
            if isEmpty { dismiss() }
        }
    }

    private var isAtFreeLimit: Bool {
        !allowance.allowsIntake(on: .now, isTrentePlusSubscribed: isTrentePlusSubscribed)
    }

    private var lockedRows: some View {
        VStack(spacing: DesignSystem.Spacing.medium.rawValue) {
            ForEach(pendingTransactions) { pending in
                row(for: pending)

                if pending != pendingTransactions.last {
                    Divider()
                }
            }
        }
        .requiresTrentePlus(message: "Unlimited Apple Pay logging with Trente+")
    }

    private func row(for pending: PendingTransaction) -> some View {
        PendingTransactionRow(
            title: pending.title,
            date: pending.date,
            amount: Double(pending.amountCents) / 100,
            currencyCode: currencyCode,
            showsActionButtons: true,
            onReview: { reviewedID = pending.id },
            onDiscard: { discard(pending) }
        )
    }

    private func discard(_ pending: PendingTransaction) {
        do {
            try PendingTransactionService.shared.discard(pending, in: modelContext)
        } catch {
            discardError = error.localizedDescription
        }
    }
}

#Preview {
    Text("Hi")
        .sheet(isPresented: .constant(true)) {
            PendingTransactionsListView(currencyCode: "EUR")
        }
        .modelContainer(DataProvider.shared.modelContainer)
}
