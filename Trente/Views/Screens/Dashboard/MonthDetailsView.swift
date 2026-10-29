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
    @FocusState private var isAmountFocused: Bool

    @State private var failure: Failure?

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
        ScrollView {
            VStack(spacing: .medium) {
                MonthDetailsComponent(
                    month: $draft,
                    isRepartitionComplete: $isRepartitionComplete,
                    isAmountFocused: $isAmountFocused
                )
                .id(resetDraft)
                ExportSection(
                    file: exportFile,
                    isEmpty: original.transactionGroups.isEmpty
                )
                DeleteSectionBox(
                    title: String(localized: "Delete Month"),
                    message: String(localized: "This action cannot be undone. All transactions associated with this month will also be deleted."),
                    onDelete: deleteMonth
                )
            }
            .padding()
        }
        .surfacePageBackground()
        .keyboardDismissButton(isVisible: isAmountFocused) { isAmountFocused = false }
        .toolbar {
            if isEditing {
                CancelToolbarItem(systemImage: "arrow.uturn.backward", action: cancelEditing)
                ConfirmToolbarItem(
                    title: "Save",
                    isDisabled: isSaveDisabled,
                    action: saveMonth
                )
            }
        }
        .navigationBarBackButtonHidden(isEditing)
        .navigationTitle(Month.name(startingOn: draft.startDate))
        .interactiveDismissDisabled(isEditing)
        .alert(String(localized: "An error occurred"), item: $failure) { failure in
            Button(String(localized: "Retry"), action: failure.retry)
            Button(String(localized: "OK"), role: .cancel) {}
        } message: { failure in
            Text(failure.message)
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
            failure = Failure(message: error.localizedDescription, retry: saveMonth)
        }
    }

    private func deleteMonth() {
        MonthService.shared.delete(month: original, in: modelContext)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            failure = Failure(message: error.localizedDescription, retry: deleteMonth)
        }
    }

    private func cancelEditing() {
        draft = .init(from: original)
        resetDraft.toggle()
    }
}

private extension MonthDetailsView {
    struct Failure {
        let message: String
        let retry: () -> Void
    }
}

#Preview {
    NavigationStack {
        MonthDetailsView(month: .sample(monthsAgo: 1))
    }
}
