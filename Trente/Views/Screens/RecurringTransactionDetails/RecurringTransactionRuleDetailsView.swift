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
    var onSave: () -> Void = {}

    @State private var isEditing = false
    @State private var draft: RecurringTransactionRuleDraft?
    @State private var validationErrors: [String] = []
    @State private var showDeleteConfirmation = false
    @State private var deleteError: String?
    @State private var isRepartitionComplete = false

    private enum EditField { case title, amount }
    @FocusState private var focusedField: EditField?

    private var totalAmount: Int {
        rule.repartition.values.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .medium) {
                    headerBox()
                    recurrenceDetailsBox()
                    autoConfirmBox()
                    repartitionBox()
                    if isEditing {
                        deleteSection()
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .interactiveDismissDisabled(isEditing)
            .keyboardDismissButton(isVisible: focusedField != nil && isEditing) { focusedField = nil }
            .onChange(of: isEditing) { _, editing in if !editing { focusedField = nil } }
            .navigationTitle(isEditing ? String(localized: "Editing") : rule.title)
            .inlineNavigationBarTitleDisplayMode()
            .toolbar { toolbarContent() }
            .alert(String(localized: "Cannot Save"), isPresented: Binding(
                get: { !validationErrors.isEmpty && isEditing },
                set: { if !$0 { validationErrors = [] } }
            )) {
                Button("OK") { validationErrors = [] }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
            .alert(String(localized: "Delete Failed"), isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerBox() -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: .small) {
                titleField()
                    .padding(.top, 12)
                frequencyTag()
            }
            .padding([.bottom, .horizontal])
        }
        .groupBoxStyle(TrenteGroupBoxStyle(withPadding: false))
    }

    @ViewBuilder
    private func titleField() -> some View {
        TextField(
            "Recurring transaction title",
            text: Binding(
                get: { isEditing ? (draft?.title ?? rule.title) : rule.title },
                set: { draft?.title = $0 }
            ),
            axis: .vertical
        )
        .focused($focusedField, equals: .title)
        .disabled(!isEditing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.title)
        .padding(isEditing ? 8 : 0)
        .background {
            if isEditing {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.2))
            }
        }
    }

    @ViewBuilder
    private func frequencyTag() -> some View {
        let description = rule.frequencyDescription
        Text(description)
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

    // MARK: - Repartition

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
                    .focused($focusedField, equals: .amount)
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

    // MARK: - Delete

    @ViewBuilder
    private func deleteSection() -> some View {
        let warningMessage = String(localized: "This action cannot be undone.")
        GroupBox(label: Label("Delete Recurring Transaction", systemImage: "trash.fill")) {
            VStack(spacing: .medium) {
                Text(warningMessage)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Recurring Transaction", systemImage: "trash.fill")
                        .font(.headline)
                }
                .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
                .confirmationDialog(String(localized: "Are you sure?"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button(String(localized: "Delete"), role: .destructive, action: deleteRule)
                    Button(String(localized: "Cancel"), role: .cancel) {}
                } message: {
                    Text(warningMessage)
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    withAnimation {
                        draft = nil
                        isEditing = false
                    }
                } label: { Label("Cancel", systemImage: "arrow.uturn.backward") }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { onTapDone() } label: { Label("Done", systemImage: "checkmark") }
            }
        } else {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation {
                        draft = RecurringTransactionRuleDraft(from: rule)
                        isEditing = true
                    }
                } label: { Label("Edit", systemImage: "pencil") }
            }
            ToolbarItem(placement: .closeButtonPlacement) {
                Button { dismiss() } label: { Label("Close", systemImage: "chevron.down") }
            }
        }
    }

    // MARK: - Actions

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
}
