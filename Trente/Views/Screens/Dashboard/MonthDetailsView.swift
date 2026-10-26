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

    @AppStorage(TransactionCSVFormat.includesNotesKey) private var exportIncludesNotes = true
    @AppStorage(TransactionCSVFormat.includesImagesKey) private var exportIncludesImages = true
    @Query private var groupsWithImages: [TransactionGroup]

    init(month: Month) {
        self.original = month
        _draft = State(initialValue: .init(from: month))
        _groupsWithImages = Query(TransactionExportRow.groupsWithImagesDescriptor(inMonth: month.id))
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
                    ExportMonthSection(
                        file: exportFile,
                        isEmpty: original.transactionGroups.isEmpty
                    )
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

    private var exportFile: TransactionsCSVFile {
        TransactionsCSVFile(
            monthIDs: [original.id],
            fileName: TransactionsCSVFile.fileName(for: original),
            format: TransactionCSVFormat(
                style: .current,
                includesNotes: exportIncludesNotes,
                includesImages: exportIncludesImages
            ),
            hasImages: !groupsWithImages.isEmpty
        )
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
        MonthService.shared.delete(month: original, in: modelContext)
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

private struct ExportMonthSection: View {
    let file: TransactionsCSVFile
    let isEmpty: Bool

    var body: some View {
        GroupBox(label: Label("Export Month", systemImage: "square.and.arrow.up")) {
            VStack(spacing: .medium) {
                Text(description)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ExportButton(title: "Export…", file: file)
                    .disabled(isEmpty)

                Text("To export several months or choose what to include, go to Settings › Export Transactions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }

    private var description: LocalizedStringKey {
        if isEmpty {
            "This month has no transactions to export yet."
        } else if file.includesImages {
            "Save this month's transactions and their images in a .zip file, with a spreadsheet (.csv) that opens in Numbers, Excel or Google Sheets."
        } else {
            "Save this month's transactions as a spreadsheet file (.csv) that opens in Numbers, Excel or Google Sheets."
        }
    }
}

private struct DeleteSection: View {
    @State private var showDeleteConfirmation = false
    let onConfirmDelete: () -> Void

    var body: some View {
        let deleteWarningMessage = String(localized: "This action cannot be undone. All transactions associated with this month will also be deleted.")
        GroupBox(label: Label("Delete Month", systemImage: "trash.fill")) {
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
