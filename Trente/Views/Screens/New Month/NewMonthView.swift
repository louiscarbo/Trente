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

    @State private var newMonth: Month?
    @State private var isRepartitionComplete: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            if let newMonth = Binding($newMonth) {
                MonthDetails(month: newMonth, isRepartitionComplete: $isRepartitionComplete)
                    .navigationTitle("New Month")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                saveMonth()
                            }
                            .disabled(isCreateButtonDisabled)
                        }
                    }
            } else {
                ProgressView("Preparing New Month...")
            }
        }
        .task {
            initializeMonth()
        }
        .alert("An error occurred", isPresented: $showErrorAlert) {
            Button("Retry") {
                saveMonth()
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(errorMessage.isEmpty ? "We couldn't create the month. Please try again." : errorMessage)
        }
    }

    private var isCreateButtonDisabled: Bool {
        guard let newMonth else { return true }
        return newMonth.idealBudgetCents <= 0 || !isRepartitionComplete
    }

    private func initializeMonth() {
        if let latestMonth = months.first {
            let calendar = Calendar.current
            let nextStartDate = calendar.date(byAdding: .day, value: 1, to: latestMonth.endDate()) ?? .now

            self.newMonth = Month(
                startDate: nextStartDate,
                currency: latestMonth.currency,
                idealBudgetCents: latestMonth.idealBudgetCents,
                idealRepartition: latestMonth.idealRepartition
            )
        } else {
            self.newMonth = Month(
                startDate: .now,
                currency: Currencies.currency(for: "EUR")!,
                idealBudgetCents: 0,
                idealRepartition: Dictionary(uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) })
            )
        }
    }

    private func saveMonth() {
        guard let newMonth else { return }
        do {
            try MonthService.shared.create(month: newMonth, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
