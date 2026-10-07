//
//  PendingTransactionReviewView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import SwiftUI
import SwiftData

struct PendingTransactionReviewLoader: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var pendingTransactions: [PendingTransaction]

    init(id: UUID) {
        _pendingTransactions = Query(filter: #Predicate<PendingTransaction> { $0.id == id })
    }

    var body: some View {
        if let pending = pendingTransactions.first {
            PendingTransactionReviewView(pending: pending)
        } else {
            Color.clear
                .onAppear { dismiss() }
        }
    }
}

struct PendingTransactionReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Month.startDate, order: .reverse) private var months: [Month]

    let pending: PendingTransaction

    @State private var draft: TransactionGroupDraft
    @State private var validationErrors: [String] = []
    @State private var deleteError: String? = nil

    @FocusState private var titleFocused: Bool
    @FocusState private var notesFocused: Bool
    @FocusState private var amountFocused: Bool

    private var isTrentePlusUser: Bool { true } // TODO: plug real entitlement

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
                TransactionHeaderBox(
                    isEditing: true,
                    currency: currency,
                    showsExpenseRow: true,
                    showsNotes: isTrentePlusUser,
                    title: $draft.title,
                    category: $draft.expenseCategory,
                    amountCents: amountBinding,
                    note: noteBinding,
                    imageData: $draft.imageAttachmentData,
                    titleFocus: $titleFocused,
                    notesFocus: $notesFocused,
                    amountFocus: $amountFocused
                )
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

    private var amountBinding: Binding<Int> {
        Binding(
            get: { draft.expenseAmountCents ?? 0 },
            set: { draft.expenseAmountCents = -abs($0) }
        )
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { draft.note ?? "" },
            set: { draft.note = $0 }
        )
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
            validationErrors = ["Failed to save changes: \(error.localizedDescription)"]
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
                    title: "Dia",
                    category: .needs
                )
            )
        }
        .modelContainer(DataProvider.shared.modelContainer)
}
