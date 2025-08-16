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
    @State private var resetDraft: Bool = false

    init(month: Month) {
        self.original = month
        _draft = State(initialValue: .init(from: month))
    }

    private var isEditing: Bool { draft != MonthDraft(from: original) }
    private var isSaveDisabled: Bool { draft.idealBudgetCents <= 0 || !isRepartitionComplete }

    var body: some View {
        NavigationStack {
            MonthDetailsComponent(
                month: $draft,
                isRepartitionComplete: $isRepartitionComplete
            )
            .id(resetDraft)
            .safeAreaInset(edge: .bottom) {
                if isEditing {
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
                }
            }
            .navigationBarBackButtonHidden(isEditing)
            .navigationTitle(MonthFormatting.name(from: draft.startDate))
        }
        .interactiveDismissDisabled(isEditing)
        .alert("An error occurred", isPresented: $showErrorAlert) {
            Button("Retry", action: saveMonth)
            Button("Cancel", role: .cancel, action: {})
        } message: {
            Text(errorMessage.isEmpty ? "We couldn't save the month. Please try again." : errorMessage)
        }
    }

    private func saveMonth() {
        do {
            draft.apply(to: original)
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

#Preview {
    MonthDetailsView(month: Month.getSampleMonthWithTransactions())
}
