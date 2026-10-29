//
//  RecurringTransactionRuleDetailsView.swift
//  Trente
//

import SwiftUI
import SwiftData

struct RecurringTransactionRuleDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isTrentePlusSubscribed) private var isTrentePlusSubscribed

    let rule: RecurringTransactionRule
    let currency: Currency
    let startInEditMode: Bool

    @State private var isEditing = false
    @State private var draft: RecurringTransactionRuleDraft
    @State private var validationErrors: [String] = []
    @State private var deleteError: String?
    @State private var stopError: String?
    @State private var isRepartitionComplete = false

    @FocusState private var titleFocused: Bool
    @FocusState private var amountFocused: Bool

    init(rule: RecurringTransactionRule, currency: Currency, startInEditMode: Bool = false) {
        self.rule = rule
        self.currency = currency
        self.startInEditMode = startInEditMode
        _draft = State(initialValue: RecurringTransactionRuleDraft(from: rule))
    }

    private var shown: Binding<RecurringTransactionRuleDraft> {
        isEditing ? $draft : .constant(RecurringTransactionRuleDraft(from: rule))
    }

    var body: some View {
        DetailEditScaffold(
            title: rule.title,
            isEditing: $isEditing,
            validationErrors: $validationErrors,
            deleteError: $deleteError,
            deleteSectionTitle: String(localized: "Delete Recurring Transaction"),
            isDoneDisabled: isSplitUnfinished,
            keyboardDismissVisible: (titleFocused || amountFocused) && isEditing,
            onDismissKeyboard: clearFocus,
            onBeginEdit: enterEditMode,
            onCancel: {
                withAnimation {
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
            if !isEditing && !rule.hasEnded {
                StopBox(title: rule.title, onStop: stopRule)
            }
        }
        .onAppear {
            if startInEditMode { enterEditMode() }
        }
        .onChange(of: isEditing) { _, editing in if !editing { clearFocus() } }
        .errorAlert("Stop Failed", message: $stopError)
    }

    private var isSplitUnfinished: Bool {
        !isExpense && draft.repartitionTotalCents != 0 && !isRepartitionComplete
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
                    text: shown.title,
                    isEditing: isEditing,
                    placeholder: String(localized: "Recurring transaction title"),
                    focus: $titleFocused
                )
                .padding(.top, 12)
                frequencyTag()
                if isExpense {
                    EditableExpenseRow(
                        isEditing: isEditing,
                        category: shown.expenseCategory,
                        amountCents: shown.expenseAmountCents,
                        currency: currency,
                        focus: $amountFocused
                    )
                }
            }
            .padding([.bottom, .horizontal])
        }
        .groupBoxStyle(TrenteGroupBoxStyle(withPadding: false))
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
                        get: { shown.wrappedValue.frequency },
                        set: { draft.setFrequency($0) }
                    ),
                    options: RecurrenceFrequency.allCases
                ) { frequency in
                    Text(frequency.displayName)
                }

                DatePicker(
                    "Start Date",
                    selection: shown.startDate,
                    in: (isEditing ? Calendar.current.startOfDay(for: .now) : .distantPast)...,
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
        if shown.wrappedValue.endDate == nil {
            if isEditing {
                Button("Add an End Date") {
                    withAnimation(.bouncy) {
                        draft.endDate = draft.startDate
                    }
                }
                .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
            }
        } else {
            let minimumEndDate = Calendar.current.date(
                byAdding: .day, value: 7,
                to: shown.wrappedValue.startDate
            ) ?? rule.startDate
            HStack {
                DatePicker(
                    "End Date",
                    selection: Binding(
                        get: { shown.wrappedValue.endDate ?? rule.startDate },
                        set: { draft.endDate = $0 }
                    ),
                    in: minimumEndDate...,
                    displayedComponents: .date
                )
                if isEditing {
                    Button("Remove End Date", systemImage: "xmark.circle.fill") {
                        withAnimation(.bouncy) {
                            draft.endDate = nil
                        }
                    }
                    .labelStyle(.iconOnly)
                    .tint(.primary)
                }
            }
        }
    }

    // MARK: - Automatic

    @ViewBuilder
    private func autoConfirmBox() -> some View {
        GroupBox(label: Label("Automatic", systemImage: "checkmark.circle.fill")) {
            VStack(alignment: .leading, spacing: .small) {
                Toggle(
                    isExpense ? String(localized: "Mark as paid automatically") : String(localized: "Mark as received automatically"),
                    isOn: shown.autoConfirm
                )
                .requiresTrentePlus(isRequired: isEditing && !shown.wrappedValue.autoConfirm)
                Group {
                    if shown.wrappedValue.autoConfirm && !isTrentePlusSubscribed {
                        Text("Paused without Trente+. Until you subscribe again, you'll be asked to confirm \(rule.title).")
                    } else {
                        Text("On the due date, \(rule.title) is added to that month's transactions.")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
        .disabled(!isEditing)
    }

    // MARK: - Category & Amount (Expense)

    private var isExpense: Bool { rule.amountCents < 0 }

    // MARK: - Repartition (Income)

    @ViewBuilder
    private func repartitionBox() -> some View {
        GroupBox(label: Label("Repartition", systemImage: "chart.pie.fill")) {
            VStack(spacing: .medium) {
                if isEditing {
                    CurrencyTextField(
                        amountCents: $draft.repartitionTotalCents,
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
                    repartition: shown.repartition,
                    amountToSplit: shown.wrappedValue.repartitionTotalCents,
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
        guard !isEditing else { return }
        withAnimation {
            draft = RecurringTransactionRuleDraft(from: rule)
            isEditing = true
        }
    }

    private func onTapDone() {
        let issues = draft.validate()
        if !issues.isEmpty {
            validationErrors = issues
            return
        }
        draft.apply(to: rule)
        do {
            try modelContext.save()
            withAnimation {
                isEditing = false
            }
        } catch {
            validationErrors = [String(localized: "Failed to save changes: \(error.localizedDescription)")]
        }
    }

    private func stopRule() {
        do {
            try RecurringTransactionService.shared.stop(rule, in: modelContext)
        } catch {
            stopError = error.localizedDescription
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
