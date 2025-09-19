//
//  MonthDetailsView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/08/2025.
//

import SwiftUI
import SwiftData

struct MonthDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let original: Month
    @State private var draft: MonthDraft

    @State private var isRepartitionComplete: Bool = false

    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var errorAction: (() -> Void)? = nil

    @State private var resetDraft: Bool = false

    init(month: Month) {
        self.original = month
        _draft = State(initialValue: .init(from: month))
    }

    private var isEditing: Bool { draft != MonthDraft(from: original) }
    private var isSaveDisabled: Bool { draft.idealBudgetCents <= 0 || !isRepartitionComplete }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .medium) {
                    MonthDetailsComponent(
                        month: $draft,
                        isRepartitionComplete: $isRepartitionComplete
                    )
                    .id(resetDraft)
                    DeleteSection(onConfirmDelete: deleteMonth)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                if isEditing {
                    editingFooter
                }
            }
            .navigationBarBackButtonHidden(isEditing)
            .navigationTitle(MonthFormatting.name(from: draft.startDate))
        }
        .interactiveDismissDisabled(isEditing)
        .alert(String(localized: "An error occurred"), isPresented: $showErrorAlert) {
            if let action = errorAction {
                Button(String(localized: "Retry"), action: action)
            }
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: showErrorAlert) {
            if !showErrorAlert { errorAction = nil }
        }
    }

    private func saveMonth() {
        do {
            draft.apply(to: original)
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            errorAction = saveMonth
            showErrorAlert = true
        }
    }

    private func deleteMonth() {
        modelContext.delete(original)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            errorAction = deleteMonth
            showErrorAlert = true
        }
    }

    private var editingFooter: some View {
        VStack(spacing: .small) {
            Button(action: saveMonth) {
                Label("Save", systemImage: "checkmark")
            }
            .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
            .disabled(isSaveDisabled)

            Button {
                draft = .init(from: original)
                resetDraft.toggle()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
        }
        .padding()
        .background {
            UnevenRoundedRectangle(
                cornerRadii:
                    RectangleCornerRadii(topLeading: 26, bottomLeading: 0, bottomTrailing: 0, topTrailing: 26)
            )
            .offset(y: 1.5)
            .fill(.regularMaterial)
            .stroke(.secondary.opacity(0.4), lineWidth: 3)
            .ignoresSafeArea()
        }
    }
}

private struct DeleteSection: View {
    @State private var showDeleteConfirmation = false
    let onConfirmDelete: () -> Void

    var body: some View {
        let deleteWarningMessage = String(localized: "This action cannot be undone. All transactions associated with this month will also be deleted.")
        GroupBox(label: Label("Delete month", systemImage: "trash.fill")) {
            VStack(spacing: .medium) {
                Text(deleteWarningMessage)
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Month", systemImage: "trash.fill")
                        .font(.headline)
                }
                .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
                .confirmationDialog(String(localized: "Are you sure?"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button(String(localized: "Delete"), role: .destructive, action: onConfirmDelete)
                    Button(String(localized: "Cancel"), role: .cancel) {}
                } message: {
                    Text(deleteWarningMessage)
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

#Preview {
    MonthDetailsView(month: Month.getSampleMonthWithTransactions())
}
