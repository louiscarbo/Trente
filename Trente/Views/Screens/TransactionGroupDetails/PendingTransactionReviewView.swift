//
//  PendingTransactionReviewView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import SwiftUI
import SwiftData

struct PendingTransactionReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isTrentePlusSubscribed) private var isTrentePlusSubscribed
    @Query(sort: \Month.startDate, order: .reverse) private var months: [Month]

    let pending: PendingTransaction

    @State private var draft: TransactionGroupDraft
    @State private var validationErrors: [String] = []
    @State private var deleteError: String? = nil
    @State private var applePayLogCount = WalletIntakeAllowance().count(on: .now)

    @FocusState private var titleFocused: Bool
    @FocusState private var notesFocused: Bool
    @FocusState private var amountFocused: Bool

    init(pending: PendingTransaction) {
        self.pending = pending
        _draft = State(initialValue: TransactionGroupDraft(from: pending))
    }

    var body: some View {
        if let currency = months.first?.currency {
            DetailEditScaffold(
                title: draft.title,
                editingTitle: String(localized: "New Wallet Expense"),
                cancelSystemImage: "xmark",
                isEditing: .constant(true),
                validationErrors: $validationErrors,
                deleteError: $deleteError,
                isDoneDisabled: !draft.validate().isEmpty,
                keyboardDismissVisible: titleFocused || notesFocused || amountFocused,
                onDismissKeyboard: clearFocus,
                onBeginEdit: {},
                onCancel: discard,
                onDone: validate
            ) {
                EditableTransactionHeader(
                    isEditing: true,
                    currency: currency,
                    showsExpenseRow: true,
                    title: $draft.title,
                    category: $draft.expenseCategory,
                    amountCents: $draft.expenseAmountCents,
                    note: $draft.note,
                    imageData: $draft.imageAttachmentData,
                    titleFocus: $titleFocused,
                    notesFocus: $notesFocused,
                    amountFocus: $amountFocused
                )
                if !isTrentePlusSubscribed {
                    AllowanceNote(
                        loggedCount: min(applePayLogCount, WalletIntakeAllowance.freeMonthlyLimit),
                        limit: WalletIntakeAllowance.freeMonthlyLimit
                    )
                }
            }
            .presentationDetents([.medium, .large])
        } else {
            ContentUnavailableView(
                "No month available",
                systemImage: "calendar",
                description: Text("Create a month to log this transaction.")
            )
        }
    }

    private func clearFocus() {
        titleFocused = false
        notesFocused = false
        amountFocused = false
    }

    private func validate() {
        let issues = draft.validate()
        guard issues.isEmpty else {
            validationErrors = issues
            return
        }
        do {
            try PendingTransactionService.shared.validate(pending, with: draft, in: modelContext)
            dismiss()
        } catch {
            validationErrors = [String(localized: "Failed to save changes: \(error.localizedDescription)")]
        }
    }

    private func discard() {
        do {
            try PendingTransactionService.shared.discard(pending, in: modelContext)
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

#Preview {
    Text("Hi")
        .sheet(isPresented: .constant(true)) {
            PendingTransactionReviewView(
                pending: PendingTransaction(
                    date: .now,
                    amountCents: -53_74,
                    title: "Dia"
                )
            )
        }
        .modelContainer(DataProvider.shared.modelContainer)
}
