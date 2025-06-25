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
    
    private var dateLimits: ClosedRange<Date> {
        TransactionService.shared.fetchTransactionDateBounds(from: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dates") {
                    DatePicker("From", selection: $dateLowerBound, in: dateLimits, displayedComponents: .date)
                    DatePicker("To", selection: $dateUpperBound, in: dateLimits, displayedComponents: .date)
                }
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Filter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
