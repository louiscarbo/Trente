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

    let transactionGroup: TransactionGroup
    let startInEditMode: Bool

    @State private var isEditing = false
    @State private var draft: TransactionGroupDraft
    @State private var validationErrors: [String] = []
    @State private var deleteError: String? = nil

    @FocusState private var titleFocused: Bool
    @FocusState private var notesFocused: Bool
    @FocusState private var amountFocused: Bool

    init(transactionGroup: TransactionGroup, startInEditMode: Bool = false) {
        self.transactionGroup = transactionGroup
        self.startInEditMode = startInEditMode
        _draft = State(initialValue: TransactionGroupDraft(from: transactionGroup))
    }

    private var shown: Binding<TransactionGroupDraft> {
        isEditing ? $draft : .constant(TransactionGroupDraft(from: transactionGroup))
    }

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
        EditableTransactionHeader(
            isEditing: isEditing,
            currency: transactionGroup.currency,
            showsExpenseRow: transactionGroup.type == .expense,
            title: shown.title,
            category: shown.expenseCategory,
            amountCents: shown.expenseAmountCents,
            note: shown.note,
            imageData: shown.imageAttachmentData,
            titleFocus: $titleFocused,
            notesFocus: $notesFocused,
            amountFocus: $amountFocused
        )
    }

    // MARK: - Income Repartition

    @ViewBuilder
    private func incomeRepartitionBox() -> some View {
        GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
            let formatter = transactionGroup.currency.roundFormatter
            IncomeRepartitionComponent(
                repartition: shown.incomeRepartition,
                amountToSplit: shown.wrappedValue.incomeAmountToSplitCents,
                formatter: formatter,
                isRepartitionComplete: Binding.constant(true)
            )
            .disabled(!isEditing)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }

    // MARK: - Actions

    private func enterEditMode() {
        guard !isEditing else { return }
        withAnimation {
            draft = TransactionGroupDraft(from: transactionGroup)
            isEditing = true
        }
    }

    private func onTapDone() {
        draft.fillMissingAmountToSplit()
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
            startDate: .now,
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
