//
//  FilterSheetView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/06/2025.
//

import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) var dismiss

    let dateLimits: ClosedRange<Date>
    @Binding var firstDay: Date
    @Binding var lastDay: Date
    @Binding var selectedCategories: Set<BudgetCategory>
    let canReset: Bool
    let onReset: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                datesSection
                categoriesSection
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset", action: onReset)
                        .disabled(!canReset)
                }
                ConfirmToolbarItem { dismiss() }
            }
            .navigationTitle("Filter")
            .inlineNavigationBarTitleDisplayMode()
        }
    }
    
    private var datesSection: some View {
        Section("Dates") {
            DatePicker("From", selection: $firstDay, in: dateLimits, displayedComponents: .date)
            DatePicker("To", selection: $lastDay, in: dateLimits, displayedComponents: .date)
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
                            .accessibilityHidden(true)
                        Text(category.name)
                    }
                }
                .tint(.primary)
                .accessibilityAddTraits(selectedCategories.contains(category) ? .isSelected : [])
            }
        }
    }
}

#Preview {
    @Previewable @State var firstDay = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
    @Previewable @State var lastDay = Date.now
    @Previewable @State var selectedCategories: Set<BudgetCategory> = [.wants]

    let monthStart = Calendar.current.date(byAdding: .day, value: -30, to: .now)!

    FilterSheetView(
        dateLimits: monthStart...Date.now,
        firstDay: $firstDay,
        lastDay: $lastDay,
        selectedCategories: $selectedCategories,
        canReset: !selectedCategories.isEmpty,
        onReset: { selectedCategories = [] }
    )
}
