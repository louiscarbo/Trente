//
//  RecurringTransactionRuleDetailsView.swift
//  Trente
//

import SwiftUI
import SwiftData

struct RecurringTransactionRuleDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State var rule: RecurringTransactionRule
    let currency: Currency
    var startInEditMode: Bool = false
    var onSave: () -> Void = {}

    @State private var isEditing = false
    @State private var draft: RecurringTransactionRuleDraft?
    @State private var validationErrors: [String] = []
    @State private var deleteError: String?
    @State private var isRepartitionComplete = false

    @FocusState private var titleFocused: Bool
    @FocusState private var amountFocused: Bool

    private var totalAmount: Int {
        rule.repartition.values.reduce(0, +)
    }

    var body: some View {
        DetailEditScaffold(
            title: rule.title,
            isEditing: $isEditing,
            validationErrors: $validationErrors,
            deleteError: $deleteError,
            deleteSectionTitle: String(localized: "Delete Recurring Transaction"),
            keyboardDismissVisible: (titleFocused || amountFocused) && isEditing,
            onDismissKeyboard: clearFocus,
            onBeginEdit: enterEditMode,
            onCancel: {
                withAnimation {
                    draft = nil
                    isEditing = false
                }
            },
            onDone: onTapDone,
            onDelete: deleteRule
        ) {
            headerBox()
            recurrenceDetailsBox()
            autoConfirmBox()
            if !isExpense {
                repartitionBox()
            }
        }
        .onAppear {
            if startInEditMode { enterEditMode() }
        }
        .onChange(of: isEditing) { _, editing in if !editing { clearFocus() } }
    }

    private func clearFocus() {
        titleFocused = false
        amountFocused = false
    }

    // MARK: - Header

    @ViewBuilder
    private func headerBox() -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: .small) {
                EditableTitleField(
                    text: titleBinding,
                    isEditing: isEditing,
                    placeholder: String(localized: "Recurring transaction title"),
                    focus: $titleFocused
                )
                .padding(.top, 12)
                frequencyTag()
                if isExpense {
                    EditableExpenseRow(
                        isEditing: isEditing,
                        category: categoryBinding,
                        amountCents: expenseAmountBinding,
                        currency: currency,
                        focus: $amountFocused
                    )
                }
            }
            .padding([.bottom, .horizontal])
        }
        .groupBoxStyle(TrenteGroupBoxStyle(withPadding: false))
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { isEditing ? (draft?.title ?? rule.title) : rule.title },
            set: { draft?.title = $0 }
        )
    }

    @ViewBuilder
    private func frequencyTag() -> some View {
        Text(rule.frequencyDescription)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                Capsule()
                    .fill(.gray.opacity(0.15))
                    .stroke(.primary.opacity(0.15))
            }
    }

    // MARK: - Recurrence Details

    @ViewBuilder
    private func recurrenceDetailsBox() -> some View {
        GroupBox(label: Label("Recurrence Details", systemImage: "calendar")) {
            VStack(spacing: .medium) {
                LabeledPicker(
                    title: "Frequency",
                    selection: Binding(
                        get: { isEditing ? (draft?.frequency ?? rule.frequency) : rule.frequency },
                        set: { draft?.frequency = $0 }
                    ),
                    options: RecurrenceFrequency.allCases
                ) { frequency in
                    Text(frequency.displayName)
                }

                DatePicker(
                    "Start Date",
                    selection: Binding(
                        get: { isEditing ? (draft?.startDate ?? rule.startDate) : rule.startDate },
                        set: { draft?.startDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                endDatePicker()
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
        .disabled(!isEditing)
    }

    @ViewBuilder
    private func endDatePicker() -> some View {
        let currentEndDate = isEditing ? draft?.endDate : rule.endDate
        if currentEndDate == nil {
            if isEditing {
                Button("Add an End Date") {
                    withAnimation(.bouncy) {
                        draft?.endDate = draft?.startDate ?? rule.startDate
                    }
                }
                .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
            }
        } else {
            let minimumEndDate = Calendar.current.date(
                byAdding: .day, value: 7,
                to: isEditing ? (draft?.startDate ?? rule.startDate) : rule.startDate
            ) ?? rule.startDate
            HStack {
                DatePicker(
                    "End Date",
                    selection: Binding(
                        get: { (isEditing ? draft?.endDate : rule.endDate) ?? rule.startDate },
                        set: { draft?.endDate = $0 }
                    ),
                    in: minimumEndDate...,
                    displayedComponents: .date
                )
                if isEditing {
                    Button {
                        withAnimation(.bouncy) {
                            draft?.endDate = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .tint(.primary)
                }
            }
        }
    }

    // MARK: - Auto-Confirm

    @ViewBuilder
    private func autoConfirmBox() -> some View {
        GroupBox(label: Label("Auto-Confirm", systemImage: "checkmark.circle.fill")) {
            Toggle(
                "Auto-confirm new instances",
                isOn: Binding(
                    get: { isEditing ? (draft?.autoConfirm ?? rule.autoConfirm) : rule.autoConfirm },
                    set: { draft?.autoConfirm = $0 }
                )
            )
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
        .disabled(!isEditing)
    }

    // MARK: - Category & Amount (Expense)

    private var isExpense: Bool { totalAmount < 0 }

    private var expenseCategory: BudgetCategory? {
        isEditing ? draft?.repartition.keys.first : rule.repartition.keys.first
    }

    private var categoryBinding: Binding<BudgetCategory?> {
        Binding(
            get: { expenseCategory },
            set: { newCategory in
                guard let newCategory else { return }
                let amount = draft?.repartitionTotalCents ?? totalAmount
                draft?.repartition = [newCategory: amount]
            }
        )
    }

    private var expenseAmountBinding: Binding<Int> {
        Binding(
            get: { isEditing ? (draft?.repartitionTotalCents ?? totalAmount) : totalAmount },
            set: { newValue in
                let signedAmount = -abs(newValue)
                draft?.repartitionTotalCents = signedAmount
                if let category = expenseCategory {
                    draft?.repartition = [category: signedAmount]
                }
            }
        )
    }

    // MARK: - Repartition (Income)

    @ViewBuilder
    private func repartitionBox() -> some View {
        GroupBox(label: Label("Repartition", systemImage: "chart.pie.fill")) {
            VStack(spacing: .medium) {
                if isEditing {
                    CurrencyTextField(
                        amountCents: Binding(
                            get: { draft?.repartitionTotalCents ?? totalAmount },
                            set: { draft?.repartitionTotalCents = $0 }
                        ),
                        currency: currency
                    )
                    .focused($amountFocused)
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.gray.opacity(0.2))
                    }
                }
                IncomeRepartitionComponent(
                    repartition: Binding(
                        get: { isEditing ? (draft?.repartition ?? rule.repartition) : rule.repartition },
                        set: { draft?.repartition = $0 }
                    ),
                    amountToSplit: isEditing
                        ? (draft?.repartitionTotalCents ?? totalAmount)
                        : totalAmount,
                    formatter: currency.roundFormatter,
                    isRepartitionComplete: $isRepartitionComplete
                )
                .disabled(!isEditing)
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }

    // MARK: - Actions

    private func enterEditMode() {
        guard !isEditing, draft == nil else { return }
        withAnimation {
            draft = RecurringTransactionRuleDraft(from: rule)
            isEditing = true
        }
    }

    private func onTapDone() {
        guard let currentDraft = draft else { return }
        let issues = currentDraft.validate()
        if !issues.isEmpty {
            validationErrors = issues
            return
        }
        currentDraft.apply(to: rule)
        do {
            try modelContext.save()
            onSave()
            withAnimation { isEditing = false }
        } catch {
            validationErrors = [String(localized: "Failed to save changes: \(error.localizedDescription)")]
        }
    }

    private func deleteRule() {
        RecurringTransactionService.shared.delete(rule: rule, in: modelContext)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}
