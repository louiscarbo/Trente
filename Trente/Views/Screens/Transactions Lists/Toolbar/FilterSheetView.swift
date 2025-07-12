//
//  FilterSheetView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/06/2025.
//

import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Binding var dateLowerBound: Date
    @Binding var dateUpperBound: Date
    @Binding var selectedCategories: Set<BudgetCategory>
    @State var allItems: [DisplayableTransaction]
    
    @State private var errorIsPresented: Bool = false
    @State private var error: Error?
    
    private var dateLimits: ClosedRange<Date> { computeDateLimits() }
    
    var body: some View {
        NavigationStack {
            Form {
                datesSection
                categoriesSection
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        dismiss()
                    }
                }
            }
            .alert("An error occured", isPresented: $errorIsPresented, presenting: error) { _ in
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: { error in
                Text("\(error.localizedDescription)")
            }
            .navigationTitle("Filter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
    
    private func computeDateLimits() -> ClosedRange<Date> {
        do {
            return try TransactionService.shared.fetchTransactionDateBounds(from: modelContext)
        } catch {
            self.error = error
            errorIsPresented = true
            return Date()...Date()
        }
    }
}
