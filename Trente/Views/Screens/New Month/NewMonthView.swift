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
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    private var isCreateButtonDisabled: Bool {
        guard let draft else { return true }
        return draft.idealBudgetCents <= 0 || !isRepartitionComplete
    }

    var body: some View {
        NavigationStack {
            if let draftBinding = Binding($draft) {
                MonthDetailsComponent(month: draftBinding, isRepartitionComplete: $isRepartitionComplete)
                    .navigationTitle("New Month")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create", action: saveMonth)
                                .disabled(isCreateButtonDisabled)
                        }
                    }
            } else {
                ProgressView("Preparing New Month...")
            }
        }
        .task { initializeMonth() }
        .alert("An error occurred", isPresented: $showErrorAlert) {
            Button("Retry") { saveMonth() }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: {
            Text(errorMessage.isEmpty ? "We couldn't create the month. Please try again." : errorMessage)
        }
    }

    private func initializeMonth() {
        if let latestMonth = months.first {
            let calendar = Calendar.current
            let nextStartDate = calendar.date(byAdding: .day, value: 1, to: latestMonth.endDate()) ?? .now

            self.draft = MonthDraft(
                startDate: nextStartDate,
                currency: latestMonth.currency,
                idealBudgetCents: latestMonth.idealBudgetCents,
                idealRepartition: latestMonth.idealRepartition
            )
        } else {
            guard let defaultCurrency = Currencies.currency(for: "EUR") else {
                errorMessage = "No currencies available to create a new month."
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
