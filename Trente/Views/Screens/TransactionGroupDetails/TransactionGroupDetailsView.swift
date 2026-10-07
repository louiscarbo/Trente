//
//  TransactionGroupDetailsView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 19/09/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct TransactionGroupDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State var transactionGroup: TransactionGroup
    var startInEditMode: Bool = false

    @State private var isEditing = false
    @State private var draft: TransactionGroupDraft?
    @State private var validationErrors: [String] = []
    @State private var deleteError: String? = nil

    @FocusState private var titleFocused: Bool
    @FocusState private var notesFocused: Bool
    @FocusState private var amountFocused: Bool

    private var isTrentePlusUser: Bool { true } // TODO: plug real entitlement

    var body: some View {
        DetailEditScaffold(
            title: transactionGroup.title,
            isEditing: $isEditing,
            validationErrors: $validationErrors,
            deleteError: $deleteError,
            deleteSectionTitle: String(localized: "Delete Transaction"),
            keyboardDismissVisible: (titleFocused || notesFocused || amountFocused) && isEditing,
            onDismissKeyboard: clearFocus,
            onBeginEdit: enterEditMode,
            onCancel: {
                withAnimation {
                    draft = nil
                    isEditing = false
                }
            },
            onDone: onTapDone,
            onDelete: deleteTransactionGroup
        ) {
            headerBox()
            if transactionGroup.type == .income {
                incomeRepartitionBox()
                    .disabled(!isEditing)
            }
        }
        .onAppear {
            if startInEditMode { enterEditMode() }
        }
        .onChange(of: isEditing) { _, editing in if !editing { clearFocus() } }
    }

    private func clearFocus() {
        titleFocused = false
        notesFocused = false
        amountFocused = false
    }

    // MARK: - Header

    private func headerBox() -> some View {
        TransactionHeaderBox(
            isEditing: isEditing,
            currency: transactionGroup.month.currency,
            showsExpenseRow: transactionGroup.type == .expense,
            showsNotes: isTrentePlusUser,
            title: titleBinding,
            category: categoryBinding,
            amountCents: expenseAmountBinding,
            note: noteBinding,
            imageData: imageDataBinding,
            titleFocus: $titleFocused,
            notesFocus: $notesFocused,
            amountFocus: $amountFocused
        )
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { isEditing ? (draft?.title ?? transactionGroup.title) : transactionGroup.title },
            set: { draft?.title = $0 }
        )
    }

    // MARK: - Category & Amount (Expense)

    private var categoryBinding: Binding<BudgetCategory?> {
        Binding(
            get: { isEditing ? draft?.expenseCategory : transactionGroup.entries.first?.category },
            set: { draft?.expenseCategory = $0 }
        )
    }

    private var expenseAmountBinding: Binding<Int> {
        Binding(
            get: {
                if isEditing {
                    -abs(draft?.expenseAmountCents ?? transactionGroup.entries.first?.amountCents ?? 0)
                } else {
                    transactionGroup.entries.first?.amountCents ?? 0
                }
            },
            set: { draft?.expenseAmountCents = -abs($0) }
        )
    }

    // MARK: - Notes & Image

    private var noteBinding: Binding<String> {
        Binding(
            get: {
                if isEditing {
                    draft?.note ?? transactionGroup.note ?? ""
                } else {
                    transactionGroup.note ?? ""
                }
            },
            set: { draft?.note = $0 }
        )
    }

    private var imageDataBinding: Binding<Data?> {
        Binding(
            get: { isEditing ? draft?.imageAttachmentData : transactionGroup.imageAttachmentData },
            set: { draft?.imageAttachmentData = $0 }
        )
    }

    // MARK: - Income Repartition

    @ViewBuilder
    private func incomeRepartitionBox() -> some View {
        GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
            let formatter = transactionGroup.month.currency.roundFormatter
            IncomeRepartitionComponent(
                repartition: Binding(
                    get: {
                        if isEditing {
                            draft?.incomeRepartition ?? [:]
                        } else {
                            Dictionary(grouping: transactionGroup.entries, by: \.category)
                                .mapValues { $0.map(\.amountCents).reduce(0, +) }
                        }
                    },
                    set: { newValue in
                        draft?.incomeRepartition = newValue
                    }
                ),
                amountToSplit: isEditing
                    ? (draft?.incomeAmountToSplitCents ?? transactionGroup.totalAmountCents)
                    : transactionGroup.totalAmountCents,
                formatter: formatter,
                isRepartitionComplete: Binding.constant(true)
            )
            .disabled(!isEditing)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }

    // MARK: - Actions

    private func enterEditMode() {
        guard !isEditing, draft == nil else { return }
        withAnimation {
            draft = TransactionGroupDraft(from: transactionGroup)
            isEditing = true
        }
    }

    private func onTapDone() {
        guard var draft = draft else { return }
        if transactionGroup.type == .income,
           draft.incomeAmountToSplitCents == 0 {
            draft.incomeAmountToSplitCents = draft.incomeRepartition.values.reduce(0, +)
            self.draft?.incomeAmountToSplitCents = draft.incomeAmountToSplitCents
        }
        let issues = draft.validate()
        if !issues.isEmpty {
            validationErrors = issues
            return
        }
        draft.apply(to: transactionGroup, context: modelContext)
        do {
            try modelContext.save()
            withAnimation {
                isEditing = false
            }
        } catch {
            validationErrors = ["Failed to save changes: \(error.localizedDescription)"]
        }
    }

    private func deleteTransactionGroup() {
        TransactionService.shared.delete(group: transactionGroup, in: modelContext)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }

    static func previewGroup() -> TransactionGroup {
        let month1 = Month(
            startDate: Date(),
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [
                .needs: 50,
                .wants: 30,
                .savingsAndDebts: 20
            ]
        )
        let imageData = imageData(named: "placeholder")
        let shopping = TransactionGroup(
            title: "Abercrombie & Fitch Lyon Part-Dieu",
            type: .expense,
            month: month1,
            note: "This is a note about the transaction and it is extremely interesting.",
            imageAttachmentData: imageData
        )
        shopping.entries = [
            TransactionEntry(amountCents: -119_99, category: .wants, group: shopping)
        ]
        return shopping
    }
}

#Preview {
    Text("Hi")
        .sheet(isPresented: .constant(true)) {
            TransactionGroupDetailsView(transactionGroup: TransactionGroupDetailsView.previewGroup())
        }
}
