//
//  FilterSheetView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/06/2025.
//

import SwiftData
import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Binding var dateLowerBound: Date
    @Binding var dateUpperBound: Date
    @Binding var selectedCategories: Set<BudgetCategory>
    
    @State private var error: Error?
    @State private var dateLimits = Date.distantPast...Date.distantFuture
    
    var body: some View {
        NavigationStack {
            Form {
                datesSection
                categoriesSection
            }
            .toolbar {
                ConfirmToolbarItem { dismiss() }
            }
            .task { loadDateLimits() }
            .alert("An error occurred", isPresented: $error.isPresent(), presenting: error) { _ in
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: { error in
                Text("\(error.localizedDescription)")
            }
            .navigationTitle("Filter")
            .inlineNavigationBarTitleDisplayMode()
        }
    }
    
    private var datesSection: some View {
        Section("Dates") {
            DatePicker("From", selection: $dateLowerBound, in: dateLimits, displayedComponents: .date)
            DatePicker("To", selection: $dateUpperBound, in: dateLimits, displayedComponents: .date)
        }
    }
    
    private var categoriesSection: some View {
        Section("Categories") {
            ForEach(BudgetCategory.allCases, id: \.self) { category in
                Button {
                    if selectedCategories.contains(category) {
                        selectedCategories.remove(category)
                    } else {
                        selectedCategories.insert(category)
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedCategories.contains(category) ?  "checkmark.circle.fill" : "circle")
                            .foregroundStyle(category.color)
                        Text(category.name)
                    }
                }
                .tint(.primary)
            }
        }
    }
    
    private func loadDateLimits() {
        do {
            dateLimits = try TransactionService.shared.fetchTransactionDateBounds(from: modelContext)
        } catch {
            self.error = error
        }
    }
}
