//
//  NewMonthView.swift
//  Trente
//
//  Created by Jules on 02/08/2025.
//

import SwiftUI
import SwiftData

struct NewMonthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Month.startDate, order: .reverse)
    private var months: [Month]

    @State private var draft: MonthDraft?
    @State private var isRepartitionComplete: Bool = false
    @FocusState private var isAmountFocused: Bool
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    private var isCreateButtonDisabled: Bool {
        guard let draft else { return true }
        return draft.idealBudgetCents <= 0 || !isRepartitionComplete
    }

    var body: some View {
        NavigationStack {
            if let draftBinding = Binding($draft) {
                ScrollView {
                    MonthDetailsComponent(
                        month: draftBinding,
                        isRepartitionComplete: $isRepartitionComplete,
                        isAmountFocused: $isAmountFocused
                    )
                        .navigationTitle("New Month")
                        .toolbar {
                            #if os(iOS)
                            CancelToolbarItem { dismiss() }
                            #endif
                            ConfirmToolbarItem(
                                title: "Create",
                                isDisabled: isCreateButtonDisabled,
                                action: saveMonth
                            )
                        }
                }
                .padding()
                .keyboardDismissButton(isVisible: isAmountFocused) { isAmountFocused = false }
            } else {
                ProgressView("Preparing New Month...")
            }
        }
        .task { initializeMonth() }
        .alert("An error occurred", isPresented: $showErrorAlert) {
            Button("Retry") { saveMonth() }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: {
            Text(errorMessage.isEmpty ? String(localized: "We couldn't create the month. Please try again.") : errorMessage)
        }
    }

    private func initializeMonth() {
        if let latestMonth = months.first {
            self.draft = MonthDraft(
                startDate: latestMonth.dateInterval.end,
                currency: latestMonth.currency,
                idealBudgetCents: latestMonth.idealBudgetCents,
                idealRepartition: latestMonth.idealRepartition
            )
        } else {
            guard let defaultCurrency = Currencies.currency(for: "EUR") else {
                errorMessage = String(localized: "No currencies available to create a new month.")
                showErrorAlert = true
                return
            }
            self.draft = MonthDraft(
                startDate: .now,
                currency: defaultCurrency,
                idealBudgetCents: 0,
                idealRepartition: Dictionary(uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) })
            )
        }
    }

    private func saveMonth() {
        guard let draft else { return }
        do {
            let month = draft.makeMonth()
            try MonthService.shared.create(month: month, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
