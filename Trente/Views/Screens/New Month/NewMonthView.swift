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

    init() {}

    var body: some View {
        NavigationStack {
            if let $newMonth {
                MonthDetails(month: $newMonth)
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
    }

    private var isCreateButtonDisabled: Bool {
        guard let newMonth else { return true }

        let repartitionSum = newMonth.idealRepartition.values.reduce(0, +)
        let isRepartitionComplete = repartitionSum == newMonth.idealBudgetCents

        return newMonth.idealBudgetCents <= 0 || !isRepartitionComplete
    }

    private func initializeMonth() {
        if let latestMonth = months.first {
            // Pre-fill data from the most recent month
            let calendar = Calendar.current
            let nextStartDate = calendar.date(byAdding: .day, value: 1, to: latestMonth.endDate()) ?? Date()

            self.newMonth = Month(
                startDate: nextStartDate,
                currency: latestMonth.currency,
                idealBudgetCents: latestMonth.idealBudgetCents,
                idealRepartition: latestMonth.idealRepartition
            )
        } else {
            // Provide default values if no months exist
            self.newMonth = Month(
                startDate: .now,
                currency: Currencies.currency(for: "USD")!,
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
            print("Failed to save the new month: \(error.localizedDescription)")
        }
    }
}
